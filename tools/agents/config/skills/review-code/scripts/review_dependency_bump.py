#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Check a PR that bumps npm dependencies for lockfile tampering and signs of a compromised publish.

For each package-lock.json the PR changes, the script compares the PR head with the merge base
and accounts for every changed entry. For each bumped package it looks up the old and new release
with `npm view` and compares publisher, install scripts, dependencies, engines, provenance and
publish age, and checks the lockfile hash against the registry. npm answers the version-range
questions: `npm ls` on the head says whether every parent's range is still satisfied, and
`npm audit` on both sides says which advisories the bump fixed, introduced or left in place.

It only reads. Nothing is written to GitHub or the registry.

Usage:
  review_dependency_bump.py <pr-number> --repo OWNER/NAME [--min-age-days N]

Exit codes:
  0  every check ran and nothing is flagged
  1  every check ran and something is flagged for a person to read
  2  the checks could not run (nothing to check, or a lookup failed); no report is printed

Requires `gh` (authenticated) and `npm` on PATH. Other lockfiles (uv.lock and the rest) are not
checked; a PR that changes one is flagged so the reviewer checks it by hand.
"""

import argparse
import json
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path, PurePosixPath
from typing import Any, Literal, NoReturn
from urllib.parse import urlparse

NPM_LOCKFILE = "package-lock.json"
UNCHECKED_LOCKFILES = frozenset(
    {
        "uv.lock",
        "poetry.lock",
        "Pipfile.lock",
        "yarn.lock",
        "pnpm-lock.yaml",
        "npm-shrinkwrap.json",
        "Cargo.lock",
        "go.sum",
        "Gemfile.lock",
        "composer.lock",
    }
)
# The lifecycle scripts npm runs when installing a package from the registry. `prepare` runs only
# for git and local installs, so a registry release that adds it changes nothing on install.
INSTALL_HOOKS = ("preinstall", "install", "postinstall")

Check = Literal[
    "unchecked",
    "integrity",
    "resolved-host",
    "publisher",
    "install-scripts",
    "dependencies",
    "engines",
    "provenance",
    "age",
    "altered-entry",
    "added-entry",
    "removed-entry",
    "tree",
    "advisories",
]


@dataclass(frozen=True)
class Flag:
    """Something a person needs to read before merging."""

    check: Check
    message: str


@dataclass(frozen=True)
class Fact:
    """A check that ran and found nothing to worry about, reported so the reader sees it ran."""

    check: Check
    message: str


Finding = Flag | Fact


def cannot_check(message: str) -> NoReturn:
    print(message, file=sys.stderr)
    sys.exit(2)


# --- Running gh and npm --------------------------------------------------------------------------


def run(cmd: Sequence[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(list(cmd), cwd=cwd, check=False, capture_output=True, text=True)
    except FileNotFoundError:
        cannot_check(f"`{cmd[0]}` is not on PATH; install it and run this again.")


def require_success(
    cmd: Sequence[str], result: subprocess.CompletedProcess[str]
) -> subprocess.CompletedProcess[str]:
    if result.returncode != 0:
        cannot_check(f"`{' '.join(cmd)}` failed:\n{result.stderr.strip()}")
    return result


def run_ok(cmd: Sequence[str], cwd: Path | None = None) -> str:
    return require_success(cmd, run(cmd, cwd)).stdout


def parse_json(text: str, source: str) -> Any:
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        cannot_check(f"{source} did not return JSON: {e}.")


# --- The PR --------------------------------------------------------------------------------------


@dataclass(frozen=True)
class PrSnapshot:
    repo: str
    number: int
    merge_base: str
    head: str
    changed_paths: tuple[str, ...]


def fetch_snapshot(repo: str, number: int) -> PrSnapshot:
    pr_cmd = ["gh", "pr", "view", str(number), "-R", repo, "--json", "baseRefName,headRefOid"]
    pr = parse_json(run_ok(pr_cmd), f"`{' '.join(pr_cmd)}`")
    if not isinstance(pr, dict) or not pr.get("baseRefName") or not pr.get("headRefOid"):
        cannot_check(f"`{' '.join(pr_cmd)}` returned no base branch or head commit: {pr!r}.")
    head = pr["headRefOid"]
    files = run_ok(
        ["gh", "api", "--paginate", f"repos/{repo}/pulls/{number}/files", "-q", ".[].filename"]
    )
    # The merge base, not the base branch's tip: commits that reached the base branch after this
    # one was cut would otherwise show up as changes the PR makes.
    merge_base = run_ok(
        [
            "gh",
            "api",
            f"repos/{repo}/compare/{pr['baseRefName']}...{head}",
            "-q",
            ".merge_base_commit.sha",
        ]
    ).strip()
    if not merge_base:
        cannot_check(f"GitHub returned no merge base for {repo}#{number}.")
    return PrSnapshot(
        repo=repo,
        number=number,
        merge_base=merge_base,
        head=head,
        changed_paths=tuple(line for line in files.splitlines() if line),
    )


def fetch_file(repo: str, path: str, sha: str) -> str | None:
    """The file's text at that commit, or None when it does not exist there."""
    cmd = [
        "gh",
        "api",
        "-H",
        "Accept: application/vnd.github.raw",
        f"repos/{repo}/contents/{path}?ref={sha}",
    ]
    result = run(cmd)
    if result.returncode != 0 and "HTTP 404" in result.stderr:
        return None
    return require_success(cmd, result).stdout


# --- Lockfiles -----------------------------------------------------------------------------------


@dataclass(frozen=True)
class LockEntry:
    install_path: str
    name: str
    version: str
    resolved: str | None
    integrity: str | None
    dev: bool
    has_install_script: bool
    raw: dict[str, Any]


@dataclass(frozen=True)
class Lockfile:
    entries: dict[str, LockEntry]


@dataclass(frozen=True)
class LockSide:
    """One side of a lockfile pair: the parsed entries, plus the text npm needs to run against."""

    lockfile: Lockfile
    lock_text: str
    manifest_text: str


def parse_lockfile(text: str, where: str) -> Lockfile:
    raw = parse_json(text, where)
    if not isinstance(raw, dict):
        cannot_check(f"{where} is not a JSON object.")
    version = raw.get("lockfileVersion")
    if version not in (2, 3):
        cannot_check(
            f"{where} uses lockfileVersion {version}; only versions 2 and 3 are supported. "
            "Regenerate it with npm 7 or later."
        )
    packages = raw.get("packages")
    if not isinstance(packages, dict):
        cannot_check(f"{where} has no `packages` object.")
    entries: dict[str, LockEntry] = {}
    for path, item in packages.items():
        # The root project and workspace links are not installed from a registry.
        if "node_modules/" not in path or not isinstance(item, dict) or item.get("link"):
            continue
        version_ = item.get("version")
        if not isinstance(version_, str):
            cannot_check(f"{where} entry {path} has no version.")
        entries[path] = LockEntry(
            install_path=path,
            name=item.get("name") or path.rsplit("node_modules/", 1)[-1],
            version=version_,
            resolved=item.get("resolved"),
            integrity=item.get("integrity"),
            dev=bool(item.get("dev") or item.get("devOptional")),
            has_install_script=bool(item.get("hasInstallScript")),
            raw=item,
        )
    return Lockfile(entries=entries)


def fetch_side(snapshot: PrSnapshot, lock_path: str, sha: str) -> LockSide | None:
    lock_text = fetch_file(snapshot.repo, lock_path, sha)
    if lock_text is None:
        return None
    manifest_path = str(PurePosixPath(lock_path).with_name("package.json"))
    manifest_text = fetch_file(snapshot.repo, manifest_path, sha)
    if manifest_text is None:
        cannot_check(f"{lock_path} exists at {sha} but {manifest_path} does not.")
    return LockSide(
        lockfile=parse_lockfile(lock_text, f"{lock_path} at {sha}"),
        lock_text=lock_text,
        manifest_text=manifest_text,
    )


# --- What changed --------------------------------------------------------------------------------


@dataclass(frozen=True)
class VersionBump:
    old: LockEntry
    new: LockEntry

    def __post_init__(self) -> None:
        assert self.old.install_path == self.new.install_path, (self.old, self.new)
        assert self.old.name == self.new.name, (self.old.name, self.new.name)
        assert self.old.version != self.new.version, self.old.version


@dataclass(frozen=True)
class Altered:
    """An entry whose version stayed the same while something else about it changed."""

    entry: LockEntry
    fields: tuple[str, ...]


@dataclass(frozen=True)
class LockfileChanges:
    bumps: tuple[VersionBump, ...]
    added: tuple[LockEntry, ...]
    removed: tuple[LockEntry, ...]
    altered: tuple[Altered, ...]

    def is_empty(self) -> bool:
        return not (self.bumps or self.added or self.removed or self.altered)


def diff_lockfiles(base: Lockfile, head: Lockfile) -> LockfileChanges:
    bumps: list[VersionBump] = []
    added: list[LockEntry] = []
    removed: list[LockEntry] = []
    altered: list[Altered] = []
    unchanged: list[str] = []
    for path in sorted(base.entries.keys() | head.entries.keys()):
        old, new = base.entries.get(path), head.entries.get(path)
        if old is None and new is not None:
            added.append(new)
        elif new is None and old is not None:
            removed.append(old)
        elif old is not None and new is not None:
            if old.name != new.name:
                # An alias now points at a different package: not a bump of one package.
                removed.append(old)
                added.append(new)
            elif old.version != new.version:
                bumps.append(VersionBump(old=old, new=new))
            elif old.raw != new.raw:
                fields = sorted(
                    k for k in old.raw.keys() | new.raw.keys() if old.raw.get(k) != new.raw.get(k)
                )
                altered.append(Altered(entry=new, fields=tuple(fields)))
            else:
                unchanged.append(path)

    # Every entry on each side is accounted for by exactly one outcome, so nothing that changed
    # can be missing from the report.
    kept = [b.new.install_path for b in bumps] + [a.entry.install_path for a in altered] + unchanged
    base_side = [e.install_path for e in removed] + kept
    head_side = [e.install_path for e in added] + kept
    assert sorted(base_side) == sorted(base.entries), "a base entry was dropped or counted twice"
    assert sorted(head_side) == sorted(head.entries), "a head entry was dropped or counted twice"
    return LockfileChanges(tuple(bumps), tuple(added), tuple(removed), tuple(altered))


# --- Releases on the registry --------------------------------------------------------------------


@dataclass(frozen=True)
class Release:
    name: str
    version: str
    integrity: str | None
    publisher: str | None
    install_hooks: dict[str, str]
    dependencies: frozenset[str]
    engines: dict[str, Any]
    has_provenance: bool
    published_at: datetime | None


def person(raw: Any) -> str | None:
    """Who published a release, as "name <email>", so a changed email reads as a change too.

    npm view flattens a person to that string; the registry's own JSON keeps it as an object.
    """
    if isinstance(raw, str):
        return raw
    if isinstance(raw, dict) and raw.get("name"):
        return f"{raw['name']} <{raw.get('email', '')}>"
    return None


def parse_release(raw: Any, spec: str) -> Release:
    # npm view returns a one-element list on some versions and a bare object on others.
    if isinstance(raw, list) and len(raw) == 1:
        raw = raw[0]
    if not isinstance(raw, dict) or not isinstance(raw.get("dist"), dict):
        cannot_check(f"`npm view {spec} --json` returned something other than one release.")
    version = str(raw.get("version"))
    scripts = raw.get("scripts") if isinstance(raw.get("scripts"), dict) else {}
    deps = {**(raw.get("dependencies") or {}), **(raw.get("optionalDependencies") or {})}
    times = raw.get("time") if isinstance(raw.get("time"), dict) else {}
    published = times.get(version)
    attestations = raw["dist"].get("attestations")
    return Release(
        name=str(raw.get("name")),
        version=version,
        integrity=raw["dist"].get("integrity"),
        publisher=person(raw.get("_npmUser")),
        install_hooks={h: scripts[h] for h in INSTALL_HOOKS if h in scripts},
        dependencies=frozenset(deps),
        engines=raw.get("engines") or {},
        has_provenance=isinstance(attestations, dict) and "provenance" in attestations,
        published_at=datetime.fromisoformat(published) if published else None,
    )


class Registry:
    def __init__(self) -> None:
        self._cache: dict[tuple[str, str], Release] = {}

    def release(self, name: str, version: str) -> Release:
        key = (name, version)
        if key not in self._cache:
            spec = f"{name}@{version}"
            text = run_ok(["npm", "view", spec, "--json"])
            self._cache[key] = parse_release(parse_json(text, f"`npm view {spec} --json`"), spec)
        return self._cache[key]


# --- Checks on one bump --------------------------------------------------------------------------


def host(url: str | None) -> str | None:
    return urlparse(url).netloc if url else None


def assess_bump(
    bump: VersionBump, old: Release, new: Release, min_age_days: int, now: datetime
) -> list[Finding]:
    findings: list[Finding] = []

    # npm leaves the hash and URL out of some entries. Absent on both sides is how the lockfile
    # already was, so it is reported rather than flagged; the PR removing one is flagged.
    match (bump.old.integrity, bump.new.integrity):
        case (None, None):
            findings.append(
                Fact("integrity", "the lockfile records no hash for this entry, before or after")
            )
        case (_, None):
            findings.append(Flag("integrity", "the lockfile no longer records a hash"))
        case (_, lock_hash) if lock_hash == new.integrity:
            findings.append(Fact("integrity", "matches the registry"))
        case (_, lock_hash):
            findings.append(
                Flag(
                    "integrity",
                    f"the lockfile has {lock_hash} but the registry has {new.integrity}",
                )
            )

    match (host(bump.old.resolved), host(bump.new.resolved)):
        case (None, None):
            findings.append(
                Fact("resolved-host", "the lockfile records no URL for this entry, before or after")
            )
        case (old_host, new_host) if old_host == new_host:
            findings.append(Fact("resolved-host", f"{new_host} (unchanged)"))
        case (old_host, None):
            findings.append(
                Flag("resolved-host", f"the lockfile no longer records a URL ({old_host})")
            )
        case (old_host, new_host):
            findings.append(Flag("resolved-host", f"changed from {old_host} to {new_host}"))

    if old.publisher == new.publisher:
        findings.append(Fact("publisher", f"{new.publisher or 'unknown'} (unchanged)"))
    else:
        findings.append(Flag("publisher", f"changed from {old.publisher} to {new.publisher}"))

    script_findings: list[Finding] = []
    if new.install_hooks and new.install_hooks != old.install_hooks:
        hooks = ", ".join(f"{h}: `{cmd}`" for h, cmd in new.install_hooks.items())
        script_findings.append(Flag("install-scripts", f"the new release runs {hooks}"))
    if bump.new.has_install_script and not bump.old.has_install_script:
        script_findings.append(
            Flag("install-scripts", "the lockfile entry is newly marked hasInstallScript")
        )
    if not script_findings:
        if new.install_hooks:
            hooks = ", ".join(new.install_hooks)
            script_findings.append(Fact("install-scripts", f"unchanged ({hooks})"))
        else:
            script_findings.append(Fact("install-scripts", "none"))
    findings += script_findings

    gained = sorted(new.dependencies - old.dependencies)
    dropped = sorted(old.dependencies - new.dependencies)
    if gained:
        findings.append(Flag("dependencies", f"the new release adds {', '.join(gained)}"))
    elif dropped:
        findings.append(Fact("dependencies", f"the new release drops {', '.join(dropped)}"))
    else:
        findings.append(Fact("dependencies", "unchanged"))

    if old.engines == new.engines:
        findings.append(Fact("engines", "unchanged"))
    else:
        findings.append(
            Flag("engines", f"changed from {json.dumps(old.engines)} to {json.dumps(new.engines)}")
        )

    match (old.has_provenance, new.has_provenance):
        case (False, False):
            findings.append(Fact("provenance", "absent on both releases"))
        case (True, True):
            findings.append(Fact("provenance", "present on both releases"))
        case (False, True):
            findings.append(Fact("provenance", "present on the new release"))
        case (True, False):
            findings.append(
                Flag("provenance", "the old release had provenance and the new one does not")
            )

    if new.published_at is None:
        findings.append(Flag("age", "the registry gave no publish time"))
    else:
        days = (now - new.published_at).days
        date = new.published_at.date().isoformat()
        if days < min_age_days:
            findings.append(
                Flag(
                    "age",
                    f"published {date}, {days} days ago, under the {min_age_days}-day threshold",
                )
            )
        else:
            findings.append(Fact("age", f"published {date}"))

    return findings


# --- Checks npm answers --------------------------------------------------------------------------


def check_tree(head_dir: Path) -> list[Finding]:
    cmd = ["npm", "ls", "--all", "--package-lock-only", "--json"]
    # npm ls exits 1 whenever it reports a problem, so the exit code alone says nothing.
    result = run(cmd, head_dir)
    report = parse_json(result.stdout, f"`{' '.join(cmd)}`")
    problems = report.get("problems", []) if isinstance(report, dict) else None
    if problems is None or (result.returncode != 0 and not problems):
        cannot_check(f"`{' '.join(cmd)}` failed:\n{result.stderr.strip()}")
    if not problems:
        return [Fact("tree", "npm ls reports no problems")]
    return [Flag("tree", str(p)) for p in problems]


@dataclass(frozen=True)
class Advisory:
    source: int
    package: str
    title: str
    severity: str
    vulnerable_range: str
    url: str


def describe_grouped(advisories: list[Advisory]) -> list[str]:
    """One line per GHSA and package, listing every vulnerable range it covers.

    npm gives each vulnerable range of one GHSA its own advisory id, so a package with copies on
    two major lines would otherwise read as two advisories.
    """
    groups: dict[tuple[str, str], list[Advisory]] = {}
    for a in sorted(advisories, key=lambda a: a.source):
        groups.setdefault((a.url, a.package), []).append(a)
    lines = []
    for (url, package), members in groups.items():
        ranges = " and ".join(a.vulnerable_range for a in members)
        first = members[0]
        lines.append(f"{first.title} ({first.severity}) in {package} {ranges}, {url}")
    return lines


def audit(side_dir: Path, side: str) -> dict[int, Advisory]:
    cmd = ["npm", "audit", "--package-lock-only", "--json"]
    # npm audit exits 1 whenever it finds a vulnerability, so the exit code alone says nothing.
    result = run(cmd, side_dir)
    report = parse_json(result.stdout, f"`{' '.join(cmd)}` on the {side}")
    if not isinstance(report, dict) or "error" in report or "vulnerabilities" not in report:
        detail = report.get("error") if isinstance(report, dict) else report
        cannot_check(f"`{' '.join(cmd)}` failed on the {side}: {detail or result.stderr.strip()}")
    advisories: dict[int, Advisory] = {}
    for vuln in report["vulnerabilities"].values():
        for via in vuln.get("via", []):
            # A string names another vulnerable package this one depends on, not an advisory.
            if isinstance(via, dict):
                advisories[via["source"]] = Advisory(
                    source=via["source"],
                    package=via["name"],
                    title=via.get("title", ""),
                    severity=via.get("severity", "unknown"),
                    vulnerable_range=via.get("range", ""),
                    url=via.get("url", ""),
                )
    return advisories


def compare_advisories(
    base: dict[int, Advisory], head: dict[int, Advisory], bumped: frozenset[str]
) -> list[Finding]:
    fixed = [base[s] for s in base.keys() - head.keys()]
    introduced = [head[s] for s in head.keys() - base.keys()]
    remaining = [head[s] for s in head.keys() & base.keys() if head[s].package in bumped]
    findings: list[Finding] = []
    findings += [Fact("advisories", f"fixed {line}") for line in describe_grouped(fixed)]
    findings += [Flag("advisories", f"introduced {line}") for line in describe_grouped(introduced)]
    findings += [
        Flag("advisories", f"still affected by {line}") for line in describe_grouped(remaining)
    ]
    untouched = len({(a.url, a.package) for a in head.values() if a.package not in bumped})
    if untouched:
        noun = "advisory affects" if untouched == 1 else "advisories affect"
        findings.append(Fact("advisories", f"{untouched} {noun} packages this PR does not change"))
    if not findings:
        findings.append(Fact("advisories", "none before or after"))
    return findings


# --- The report ----------------------------------------------------------------------------------


@dataclass(frozen=True)
class Section:
    title: str
    findings: tuple[Finding, ...]


def render_finding(f: Finding) -> str:
    match f:
        case Flag(check, message):
            return f"- FLAG {check}: {message}"
        case Fact(check, message):
            return f"- {check}: {message}"


def check_lockfile(
    snapshot: PrSnapshot, lock_path: str, registry: Registry, min_age_days: int
) -> list[Section] | None:
    """The report sections for one lockfile, or None when it did not change."""
    base = fetch_side(snapshot, lock_path, snapshot.merge_base)
    head = fetch_side(snapshot, lock_path, snapshot.head)
    empty = Lockfile(entries={})
    changes = diff_lockfiles(base.lockfile if base else empty, head.lockfile if head else empty)
    if changes.is_empty():
        return None

    sections: list[Section] = []
    now = datetime.now(UTC)
    for bump in changes.bumps:
        old = registry.release(bump.old.name, bump.old.version)
        new = registry.release(bump.new.name, bump.new.version)
        kind = "dev" if bump.new.dev else "runtime"
        title = (
            f"{bump.new.name} {bump.old.version} -> {bump.new.version} ({kind}) "
            f"at {bump.new.install_path}"
        )
        sections.append(Section(title, tuple(assess_bump(bump, old, new, min_age_days, now))))

    other: list[Finding] = [
        Flag("altered-entry", f"{a.entry.install_path} changed {', '.join(a.fields)}")
        for a in changes.altered
    ]
    other += [Flag("added-entry", f"{e.install_path} {e.version}") for e in changes.added]
    other += [Fact("removed-entry", f"{e.install_path} {e.version}") for e in changes.removed]
    if other:
        sections.append(Section("Other changes", tuple(other)))

    if head is None:
        return sections
    with tempfile.TemporaryDirectory() as tmp:
        dirs: dict[str, Path] = {}
        for name, side in (("base", base), ("head", head)):
            if side is None:
                continue
            # npm ls and npm audit read the lockfile and manifest from the working directory.
            d = Path(tmp) / name
            d.mkdir()
            (d / "package-lock.json").write_text(side.lock_text)
            (d / "package.json").write_text(side.manifest_text)
            dirs[name] = d
        sections.append(Section("Tree", tuple(check_tree(dirs["head"]))))
        base_advisories = audit(dirs["base"], "base") if "base" in dirs else {}
        head_advisories = audit(dirs["head"], "head")
    bumped = frozenset(b.new.name for b in changes.bumps)
    advisories = compare_advisories(base_advisories, head_advisories, bumped)
    sections.append(Section("Advisories", tuple(advisories)))
    return sections


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("pr", type=int, help="PR number")
    parser.add_argument(
        "--repo",
        required=True,
        help="repository as OWNER/NAME; required so the check cannot run against a PR with the "
        "same number in whatever repo the shell happens to be in",
    )
    parser.add_argument(
        "--min-age-days",
        type=int,
        default=7,
        help="flag a release published fewer than this many days ago (default: 7)",
    )
    args = parser.parse_args()

    snapshot = fetch_snapshot(args.repo, args.pr)
    lock_paths = [p for p in snapshot.changed_paths if PurePosixPath(p).name == NPM_LOCKFILE]
    unchecked = [p for p in snapshot.changed_paths if PurePosixPath(p).name in UNCHECKED_LOCKFILES]
    if not lock_paths:
        cannot_check(
            f"{args.repo}#{args.pr} changes no {NPM_LOCKFILE}, so there is nothing for this "
            "script to check. It checks npm lockfiles only; check any other lockfile by hand."
        )

    registry_url = run_ok(["npm", "config", "get", "registry"]).strip()
    registry = Registry()
    results: list[tuple[str, list[Section]]] = []
    for path in lock_paths:
        sections = check_lockfile(snapshot, path, registry, args.min_age_days)
        if sections is not None:
            results.append((path, sections))
    if not results:
        cannot_check(
            f"Every {NPM_LOCKFILE} in {args.repo}#{args.pr} is identical at the merge base and "
            "the head, so there is nothing to check."
        )

    lines = [
        f"# Dependency bump check: {args.repo}#{args.pr}",
        "",
        f"Compared head {snapshot.head} with merge base {snapshot.merge_base}. "
        f"Releases looked up in {registry_url}.",
        "",
    ]
    all_findings: list[Finding] = []
    if unchecked:
        not_checked = [
            Flag("unchecked", f"{p} is not an npm lockfile; check it by hand") for p in unchecked
        ]
        all_findings += not_checked
        lines += ["## Not checked", *map(render_finding, not_checked), ""]
    for lock_path, sections in results:
        lines += [f"## {lock_path}", ""]
        for section in sections:
            lines += [f"### {section.title}", *map(render_finding, section.findings), ""]
            all_findings += section.findings
    flagged = sum(1 for f in all_findings if isinstance(f, Flag))
    lines.append(f"{flagged} flag{'' if flagged == 1 else 's'}.")
    print("\n".join(lines))
    sys.exit(1 if flagged else 0)


if __name__ == "__main__":
    main()
