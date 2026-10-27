#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["packaging"]
# ///
"""Check a PR that bumps npm or uv dependencies for lockfile tampering and signs of a compromised
publish.

For each package-lock.json and uv.lock the PR changes, the script compares the PR head with the
merge base and accounts for every changed entry.

For npm, it looks up the old and new release of each bumped package with `npm view` and compares
publisher, install scripts, dependencies, engines, provenance and publish age, and checks the
lockfile hash against the registry. `npm ls` on the head says whether every parent's range is
still satisfied, and `npm audit` on both sides says which advisories the bump fixed, introduced or
left in place.

For uv, it reads each bumped release from PyPI with `curl` and checks every locked file's hash,
the registry source, the publisher its attestations name, new requirements, `requires_python`,
yanked files, whether a wheel is still locked, and upload age. Each package that depends on the
bumped one must still allow the new version, and `uv audit` on both sides lists the advisories.
Only pypi.org and OSV are contacted, never the project's own index: a package locked from another
index is flagged for a person to check.

It only reads. Nothing is written to GitHub or any registry.

Usage:
  review_dependency_bump.py <pr-number> --repo OWNER/NAME [--min-age-days N]

Exit codes:
  0  every check ran and nothing is flagged
  1  every check ran and something is flagged for a person to read
  2  the checks could not run (nothing to check, or a lookup failed); no report is printed

Requires `gh` (authenticated) on PATH, plus `npm` for npm lockfiles and `curl` and `uv` for uv.lock.
Other lockfiles are not checked; a PR that changes one is flagged so the reviewer checks it by hand.
"""

import argparse
import json
import re
import subprocess
import sys
import tempfile
import tomllib
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path, PurePosixPath
from typing import Any, Literal, NoReturn, TypeVar
from urllib.parse import urlparse

from packaging.requirements import InvalidRequirement, Requirement
from packaging.specifiers import InvalidSpecifier, SpecifierSet
from packaging.utils import canonicalize_name
from packaging.version import InvalidVersion, Version

NPM_LOCKFILE = "package-lock.json"
UV_LOCKFILE = "uv.lock"
PYPI = "https://pypi.org"
UNCHECKED_LOCKFILES = frozenset(
    {
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
    "release",
    "hashes",
    "source",
    "python",
    "yanked",
    "wheels",
    "parents",
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
    # npm's id for one vulnerable range of a GHSA; uv reports one entry per advisory, so 0 there.
    source: int
    package: str
    title: str
    severity: str | None
    vulnerable_range: str
    url: str


AdvisoryKey = TypeVar("AdvisoryKey")


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
        severity = f" ({first.severity})" if first.severity else ""
        lines.append(f"{first.title}{severity} in {package} {ranges}, {url}")
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
    base: dict[AdvisoryKey, Advisory], head: dict[AdvisoryKey, Advisory], bumped: frozenset[str]
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


# --- uv.lock -------------------------------------------------------------------------------------


@dataclass(frozen=True)
class LockedFile:
    filename: str
    sha256: str | None
    is_wheel: bool


@dataclass(frozen=True)
class PypiSource:
    index: str


@dataclass(frozen=True)
class OtherSource:
    """An index other than PyPI, or a URL, git or path source: nothing this script may contact."""

    description: str


@dataclass(frozen=True)
class UvPackage:
    name: str
    version: str
    source: PypiSource | OtherSource
    files: tuple[LockedFile, ...]
    # Every package this one's dependency edges name, extras included.
    dependencies: frozenset[str]
    raw: dict[str, Any]


@dataclass(frozen=True)
class ProjectRoot:
    """The project's own entries: where the runtime and dev graphs start, and its requirements."""

    names: frozenset[str]
    runtime: frozenset[str]
    dev: frozenset[str]
    # (project name, requirement text) for every requirement the project declares.
    requirements: tuple[tuple[str, str], ...]


@dataclass(frozen=True)
class UvLockfile:
    # Keyed by name, or by name==version for a name the lockfile holds at more than one version.
    packages: dict[str, UvPackage]
    project: ProjectRoot
    # The oldest Python the project supports, from the lockfile's own requires-python.
    lowest_python: Version | None
    # For each package, the extras some dependency edge in the lockfile asks for.
    requested_extras: dict[str, frozenset[str]]


@dataclass(frozen=True)
class UvSide:
    lockfile: UvLockfile
    lock_text: str
    project_text: str


def edges(items: Any) -> list[dict[str, Any]]:
    return [e for e in items if isinstance(e, dict)] if isinstance(items, list) else []


def edge_names(raw: dict[str, Any]) -> frozenset[str]:
    names = {e.get("name") for e in edges(raw.get("dependencies"))}
    for group in (raw.get("optional-dependencies") or {}).values():
        names |= {e.get("name") for e in edges(group)}
    return frozenset(canonicalize_name(n) for n in names if isinstance(n, str))


def requested_extras(items: list[dict[str, Any]]) -> dict[str, frozenset[str]]:
    requested: dict[str, set[str]] = {}
    for item in items:
        groups = [item.get("dependencies")]
        groups += list((item.get("optional-dependencies") or {}).values())
        groups += list((item.get("dev-dependencies") or {}).values())
        for edge in (e for g in groups for e in edges(g)):
            name, extras = edge.get("name"), edge.get("extra")
            if isinstance(name, str) and isinstance(extras, list):
                requested.setdefault(canonicalize_name(name), set()).update(
                    canonicalize_name(x) for x in extras if isinstance(x, str)
                )
    return {name: frozenset(extras) for name, extras in requested.items()}


def lowest_python(requires_python: Any) -> Version | None:
    """The oldest Python a requires-python range allows, when a lower bound states it."""
    if not isinstance(requires_python, str):
        return None
    try:
        specifiers = SpecifierSet(requires_python)
    except InvalidSpecifier:
        return None
    bounds = [
        Version(s.version.removesuffix(".*"))
        for s in specifiers
        if s.operator in (">=", "==", "~=", "===")
    ]
    return max(bounds) if bounds else None


def closure(start: set[str], graph: dict[str, frozenset[str]]) -> frozenset[str]:
    seen: set[str] = set()
    todo = list(start)
    # Each name is visited once, so the walk ends after at most len(graph) steps.
    while todo:
        name = todo.pop()
        if name in seen:
            continue
        seen.add(name)
        todo += graph.get(name, frozenset())
    return frozenset(seen)


def parse_uv_lockfile(text: str, where: str) -> UvLockfile:
    try:
        raw = tomllib.loads(text)
    except tomllib.TOMLDecodeError as e:
        cannot_check(f"{where} is not valid TOML: {e}.")
    if raw.get("version") != 1:
        cannot_check(
            f"{where} is uv.lock version {raw.get('version')}; only version 1 is supported."
        )
    items = raw.get("package")
    if not isinstance(items, list):
        cannot_check(f"{where} has no [[package]] entries.")

    packages: list[UvPackage] = []
    projects: list[dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            cannot_check(f"{where} has a [[package]] entry that is not a table.")
        name, version, source = item.get("name"), item.get("version"), item.get("source")
        if not isinstance(name, str) or not isinstance(source, dict):
            cannot_check(f"{where} has a package with no name or source: {item!r}.")
        if {"virtual", "editable"} & source.keys():
            # The project itself, or a workspace member: not something a release can bump.
            projects.append(item)
            continue
        if not isinstance(version, str):
            cannot_check(f"{where} entry {name} has no version.")
        files: list[LockedFile] = []
        for file, is_wheel in [(item.get("sdist"), False)] + [
            (w, True) for w in item.get("wheels") or []
        ]:
            if file is None:
                continue
            url, hash_ = file.get("url"), file.get("hash")
            if not isinstance(url, str):
                cannot_check(f"{where} entry {name} {version} has a file with no URL.")
            if hash_ is not None and not (isinstance(hash_, str) and hash_.startswith("sha256:")):
                cannot_check(f"{where} entry {name} {version} has a hash that is not sha256.")
            files.append(
                LockedFile(
                    filename=PurePosixPath(urlparse(url).path).name,
                    sha256=hash_.removeprefix("sha256:") if hash_ else None,
                    is_wheel=is_wheel,
                )
            )
        index = source.get("registry")
        parsed_source: PypiSource | OtherSource = (
            PypiSource(index)
            if isinstance(index, str) and urlparse(index).netloc == "pypi.org"
            else OtherSource(str(index) if index else json.dumps(source))
        )
        packages.append(
            UvPackage(
                name=canonicalize_name(name),
                version=version,
                source=parsed_source,
                files=tuple(files),
                dependencies=edge_names(item),
                raw=item,
            )
        )
    if not projects:
        cannot_check(f"{where} has no entry for the project itself.")

    graph: dict[str, frozenset[str]] = {}
    for p in packages:
        graph[p.name] = graph.get(p.name, frozenset()) | p.dependencies
    runtime_start: set[str] = set()
    dev_start: set[str] = set()
    requirements: list[tuple[str, str]] = []
    for item in projects:
        runtime_start |= edge_names(item)
        for group in (item.get("dev-dependencies") or {}).values():
            dev_start |= {canonicalize_name(e["name"]) for e in edges(group) if "name" in e}
        metadata = item.get("metadata") or {}
        declared = edges(metadata.get("requires-dist"))
        for group in (metadata.get("requires-dev") or {}).values():
            declared += edges(group)
        for req in declared:
            text = req.get("name", "") + req.get("specifier", "")
            if req.get("marker"):
                text += f"; {req['marker']}"
            requirements.append((item["name"], text))
    runtime = closure(runtime_start, graph)

    counts: dict[str, int] = {}
    for p in packages:
        counts[p.name] = counts.get(p.name, 0) + 1
    keyed = {p.name if counts[p.name] == 1 else f"{p.name}=={p.version}": p for p in packages}
    return UvLockfile(
        packages=keyed,
        project=ProjectRoot(
            names=frozenset(canonicalize_name(p["name"]) for p in projects),
            runtime=runtime,
            dev=closure(dev_start, graph) - runtime,
            requirements=tuple(requirements),
        ),
        lowest_python=lowest_python(raw.get("requires-python")),
        requested_extras=requested_extras(items),
    )


def fetch_uv_side(snapshot: PrSnapshot, lock_path: str, sha: str) -> UvSide | None:
    lock_text = fetch_file(snapshot.repo, lock_path, sha)
    if lock_text is None:
        return None
    project_path = str(PurePosixPath(lock_path).with_name("pyproject.toml"))
    project_text = fetch_file(snapshot.repo, project_path, sha)
    if project_text is None:
        cannot_check(f"{lock_path} exists at {sha} but {project_path} does not.")
    return UvSide(
        lockfile=parse_uv_lockfile(lock_text, f"{lock_path} at {sha}"),
        lock_text=lock_text,
        project_text=project_text,
    )


@dataclass(frozen=True)
class UvBump:
    old: UvPackage
    new: UvPackage

    def __post_init__(self) -> None:
        assert self.old.name == self.new.name, (self.old.name, self.new.name)
        assert self.old.version != self.new.version, self.old.version


@dataclass(frozen=True)
class UvAltered:
    package: UvPackage
    fields: tuple[str, ...]


@dataclass(frozen=True)
class UvLockfileChanges:
    bumps: tuple[UvBump, ...]
    added: tuple[UvPackage, ...]
    removed: tuple[UvPackage, ...]
    altered: tuple[UvAltered, ...]

    def is_empty(self) -> bool:
        return not (self.bumps or self.added or self.removed or self.altered)


def diff_uv_lockfiles(base: UvLockfile, head: UvLockfile) -> UvLockfileChanges:
    bumps: list[UvBump] = []
    added: list[UvPackage] = []
    removed: list[UvPackage] = []
    altered: list[UvAltered] = []
    base_side: list[str] = []
    head_side: list[str] = []
    for key in sorted(base.packages.keys() | head.packages.keys()):
        old, new = base.packages.get(key), head.packages.get(key)
        if old is None and new is not None:
            added.append(new)
            head_side.append(key)
        elif new is None and old is not None:
            removed.append(old)
            base_side.append(key)
        elif old is not None and new is not None:
            if old.version != new.version:
                bumps.append(UvBump(old=old, new=new))
            elif old.raw != new.raw:
                fields = sorted(
                    k for k in old.raw.keys() | new.raw.keys() if old.raw.get(k) != new.raw.get(k)
                )
                altered.append(UvAltered(package=new, fields=tuple(fields)))
            base_side.append(key)
            head_side.append(key)

    # Every package on each side is accounted for by exactly one outcome, so nothing that changed
    # can be missing from the report.
    assert sorted(base_side) == sorted(base.packages), "a base package was dropped or counted twice"
    assert sorted(head_side) == sorted(head.packages), "a head package was dropped or counted twice"
    assert len(base_side) == len(removed) + len(head_side) - len(added), "outcomes do not add up"
    return UvLockfileChanges(tuple(bumps), tuple(added), tuple(removed), tuple(altered))


# --- Releases on PyPI ----------------------------------------------------------------------------


@dataclass(frozen=True)
class PypiFile:
    sha256: str | None
    yanked_reason: str | None
    yanked: bool
    uploaded_at: datetime | None


@dataclass(frozen=True)
class PypiRelease:
    name: str
    version: str
    requires_dist: tuple[Requirement, ...]
    requires_python: str | None
    files: dict[str, PypiFile]


@dataclass(frozen=True)
class Attestation:
    """Who published one locked file, by its attestation, or None when it has none."""

    filename: str
    publisher: str | None


def curl(url: str, *headers: str) -> str | None:
    """The body at a PyPI URL, or None for a 404.

    curl rather than Python's HTTP client: it uses the system's certificates, so it works behind a
    proxy that re-signs TLS, where Python's own certificate store fails.
    """
    cmd = ["curl", "-sS", "--fail", "--max-time", "30"]
    for h in headers:
        cmd += ["-H", h]
    cmd.append(url)
    result = run(cmd)
    # curl --fail exits 22 for an HTTP error status and names the status on stderr.
    if result.returncode == 22 and "404" in result.stderr:
        return None
    return require_success(cmd, result).stdout


def parse_time(raw: Any) -> datetime | None:
    if not isinstance(raw, str):
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None


def parse_pypi_release(raw: Any, name: str, version: str, url: str) -> PypiRelease:
    if not isinstance(raw, dict) or not isinstance(raw.get("info"), dict):
        cannot_check(f"{url} returned something other than one PyPI release.")
    urls = raw.get("urls")
    if not isinstance(urls, list):
        cannot_check(f"{url} lists no files.")
    requirements: list[Requirement] = []
    for line in raw["info"].get("requires_dist") or []:
        try:
            requirements.append(Requirement(line))
        except InvalidRequirement as e:
            cannot_check(f"{url} lists a requirement packaging cannot read, {line!r}: {e}.")
    files: dict[str, PypiFile] = {}
    for f in urls:
        if not isinstance(f, dict) or not isinstance(f.get("filename"), str):
            cannot_check(f"{url} lists a file with no filename.")
        digests = f.get("digests") if isinstance(f.get("digests"), dict) else {}
        files[f["filename"]] = PypiFile(
            sha256=digests.get("sha256"),
            yanked=bool(f.get("yanked")),
            yanked_reason=f.get("yanked_reason"),
            uploaded_at=parse_time(f.get("upload_time_iso_8601")),
        )
    return PypiRelease(
        name=name,
        version=version,
        requires_dist=tuple(requirements),
        requires_python=raw["info"].get("requires_python") or None,
        files=files,
    )


def describe_publisher(raw: Any) -> str:
    if not isinstance(raw, dict):
        return "an unreadable publisher"
    words = [str(raw.get(k)) for k in ("kind", "repository", "workflow") if raw.get(k)]
    if raw.get("environment"):
        words.append(f"({raw['environment']})")
    return " ".join(words) or json.dumps(raw)


class Pypi:
    def __init__(self) -> None:
        self._releases: dict[tuple[str, str], PypiRelease | None] = {}
        self._provenance_urls: dict[str, dict[str, str | None]] = {}

    def release(self, name: str, version: str) -> PypiRelease | None:
        """The release, or None when PyPI has no such release."""
        key = (name, version)
        if key not in self._releases:
            url = f"{PYPI}/pypi/{name}/{version}/json"
            text = curl(url)
            self._releases[key] = (
                None
                if text is None
                else parse_pypi_release(parse_json(text, url), name, version, url)
            )
        return self._releases[key]

    def attestations(self, name: str, filenames: Sequence[str]) -> list[Attestation]:
        if name not in self._provenance_urls:
            url = f"{PYPI}/simple/{name}/"
            text = curl(url, "Accept: application/vnd.pypi.simple.v1+json")
            index = parse_json(text or "{}", url)
            files = index.get("files") if isinstance(index, dict) else None
            if not isinstance(files, list):
                cannot_check(f"{url} lists no files.")
            self._provenance_urls[name] = {
                f["filename"]: f.get("provenance")
                for f in files
                if isinstance(f, dict) and isinstance(f.get("filename"), str)
            }
        urls = self._provenance_urls[name]

        def one(filename: str) -> Attestation:
            url = urls.get(filename)
            if not url:
                return Attestation(filename, None)
            text = curl(url)
            doc = parse_json(text or "{}", url)
            bundles = doc.get("attestation_bundles") if isinstance(doc, dict) else None
            publishers = sorted(
                {
                    describe_publisher(b.get("publisher"))
                    for b in bundles or []
                    if isinstance(b, dict)
                }
            )
            return Attestation(filename, ", ".join(publishers) or None)

        # One request per locked file, and a release can lock dozens of wheels.
        with ThreadPoolExecutor(max_workers=8) as pool:
            return list(pool.map(one, filenames))


# --- Checks on one uv bump -----------------------------------------------------------------------


EXTRA_CLAUSE = re.compile(r"""^extra\s*==\s*["']([^"']+)["']$""")


def split_top_level(marker: str, word: str) -> list[str]:
    """The parts of a marker between each ` and ` or ` or ` outside parentheses and quotes."""
    parts: list[str] = []
    depth, quote, start = 0, "", 0
    sep = f" {word} "
    for i, ch in enumerate(marker):
        if quote:
            quote = "" if ch == quote else quote
        elif ch in "\"'":
            quote = ch
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif depth == 0 and marker.startswith(sep, i):
            parts.append(marker[start:i])
            start = i + len(sep)
    parts.append(marker[start:])
    return [part.strip() for part in parts]


def unrequested_extra(requirement: Requirement, requested: frozenset[str]) -> str | None:
    """The extra a requirement sits under, when its marker needs that extra and nothing requests it.

    The marker needs the extra only when `extra == "x"` is one of the clauses joined by `and` at
    its top level. A top-level `or` lets the requirement install without it, since `and` binds
    tighter: `a or b and extra == "x"` installs whenever `a` holds.
    """
    if requirement.marker is None:
        return None
    marker = str(requirement.marker)
    if len(split_top_level(marker, "or")) > 1:
        return None
    extras = [m.group(1) for c in split_top_level(marker, "and") if (m := EXTRA_CLAUSE.match(c))]
    if len(extras) != 1 or canonicalize_name(extras[0]) in requested:
        return None
    return extras[0]


def describe_wheels(package: UvPackage) -> str:
    wheels = sum(1 for f in package.files if f.is_wheel)
    sdist = any(not f.is_wheel for f in package.files)
    match (wheels, sdist):
        case (0, True):
            return "an sdist only"
        case (0, False):
            return "no files"
        case (_, True):
            return f"{wheels} wheel{'' if wheels == 1 else 's'} and an sdist"
        case _:
            return f"{wheels} wheel{'' if wheels == 1 else 's'}"


def assess_uv_bump(
    bump: UvBump,
    old: PypiRelease,
    new: PypiRelease,
    old_attested: list[Attestation],
    new_attested: list[Attestation],
    head: UvLockfile,
    min_age_days: int,
    now: datetime,
) -> list[Finding]:
    assert (old.name, old.version) == (bump.old.name, bump.old.version), (old.name, old.version)
    assert (new.name, new.version) == (bump.new.name, bump.new.version), (new.name, new.version)
    findings: list[Finding] = []

    hash_flags: list[Finding] = []
    for f in bump.new.files:
        on_pypi = new.files.get(f.filename)
        match (f.sha256, on_pypi):
            case (_, None):
                hash_flags.append(
                    Flag("hashes", f"{f.filename} is locked but PyPI does not list it")
                )
            case (None, _):
                hash_flags.append(Flag("hashes", f"{f.filename} is locked with no hash"))
            case (locked, pypi_file) if locked != pypi_file.sha256:
                hash_flags.append(
                    Flag(
                        "hashes",
                        f"{f.filename}: the lockfile has sha256:{locked} "
                        f"but PyPI has sha256:{pypi_file.sha256}",
                    )
                )
    if not bump.new.files:
        hash_flags.append(Flag("hashes", "the lockfile locks no files for this release"))
    n = len(bump.new.files)
    findings += hash_flags or [
        Fact("hashes", f"{n} locked file{'' if n == 1 else 's'} match{'es' if n == 1 else ''} PyPI")
    ]

    assert isinstance(bump.new.source, PypiSource) and isinstance(bump.old.source, PypiSource)
    if bump.old.source == bump.new.source:
        findings.append(Fact("source", f"{urlparse(bump.new.source.index).netloc} (unchanged)"))
    else:
        findings.append(
            Flag("source", f"changed from {bump.old.source.index} to {bump.new.source.index}")
        )

    old_publishers = sorted({a.publisher for a in old_attested if a.publisher})
    new_publishers = sorted({a.publisher for a in new_attested if a.publisher})
    match (old_publishers, new_publishers):
        case ([], []):
            findings.append(
                Fact("publisher", "PyPI names no publisher; neither release has attestations")
            )
        case ([], _):
            findings.append(
                Fact(
                    "publisher",
                    f"{'; '.join(new_publishers)} (the old release had no attestations)",
                )
            )
        case (o, n_) if o == n_:
            findings.append(Fact("publisher", f"{'; '.join(n_)} (unchanged)"))
        case (o, n_):
            findings.append(
                Flag(
                    "publisher",
                    f"changed from {'; '.join(o)} to {'; '.join(n_) or 'no attestations'}",
                )
            )

    old_count = sum(1 for a in old_attested if a.publisher)
    new_count = sum(1 for a in new_attested if a.publisher)
    counts = (
        f"{new_count} of {len(new_attested)} locked files attested "
        f"(old release: {old_count} of {len(old_attested)})"
    )
    old_all = old_count == len(old_attested) > 0
    new_all = new_count == len(new_attested) > 0
    if old_all and not new_all:
        findings.append(Flag("provenance", counts))
    elif old_count == new_count == 0:
        findings.append(Fact("provenance", "absent on both releases"))
    else:
        findings.append(Fact("provenance", counts))

    old_names = {canonicalize_name(r.name) for r in old.requires_dist}
    new_names = {canonicalize_name(r.name) for r in new.requires_dist}
    gained = sorted(new_names - old_names)
    requested = head.requested_extras.get(bump.new.name, frozenset())
    unused: dict[str, str] = {}
    for name in gained:
        extras = {
            unrequested_extra(r, requested)
            for r in new.requires_dist
            if canonicalize_name(r.name) == name
        }
        if None not in extras:
            unused[name] = ", ".join(sorted(e for e in extras if e))
    if installed := [n for n in gained if n not in unused]:
        findings.append(Flag("dependencies", f"the new release adds {', '.join(installed)}"))
    for name, extra in unused.items():
        findings.append(
            Fact(
                "dependencies",
                f"the new release adds {name} under the {extra} extra, which nothing in the "
                "lockfile requests",
            )
        )
    if not gained:
        dropped = sorted(old_names - new_names)
        message = f"the new release drops {', '.join(dropped)}" if dropped else "unchanged"
        findings.append(Fact("dependencies", message))

    lowest = head.lowest_python
    changed = f"changed from {old.requires_python} to {new.requires_python}"
    if old.requires_python == new.requires_python:
        findings.append(Fact("python", f"unchanged ({new.requires_python or 'any'})"))
    elif lowest is None or new.requires_python is None:
        findings.append(Flag("python", changed))
    elif SpecifierSet(new.requires_python).contains(lowest, prereleases=True):
        findings.append(
            Fact(
                "python",
                f"{changed}, which still allows Python {lowest}, the lowest this project supports",
            )
        )
    else:
        findings.append(
            Flag(
                "python",
                f"{changed}, which excludes Python {lowest}, the lowest this project supports",
            )
        )

    yanked = [
        Flag("yanked", f"{f.filename} is yanked: {pf.yanked_reason or 'no reason given'}")
        for f in bump.new.files
        if (pf := new.files.get(f.filename)) and pf.yanked
    ]
    findings += yanked or [Fact("yanked", "none")]

    old_has_wheel = any(f.is_wheel for f in bump.old.files)
    new_has_wheel = any(f.is_wheel for f in bump.new.files)
    if old_has_wheel and not new_has_wheel:
        findings.append(
            Flag(
                "wheels",
                "the new release locks no wheel where the old one did, so installing it builds "
                "the sdist and runs its build code",
            )
        )
    else:
        findings.append(Fact("wheels", describe_wheels(bump.new)))

    times = sorted(
        t for f in bump.new.files if (pf := new.files.get(f.filename)) and (t := pf.uploaded_at)
    )
    if not times:
        findings.append(Flag("age", "PyPI gave no upload time for the locked files"))
    else:
        first, last = times[0].date().isoformat(), times[-1].date().isoformat()
        uploaded = first if first == last else f"{first} to {last}"
        # The newest file decides: a wheel added after the release still runs on install.
        days = (now - times[-1]).days
        if days < min_age_days:
            findings.append(
                Flag(
                    "age",
                    f"uploaded {uploaded}, the newest file {days} days ago, "
                    f"under the {min_age_days}-day threshold",
                )
            )
        else:
            findings.append(Fact("age", f"uploaded {uploaded}"))
    return findings


def check_parents(head: UvLockfile, bumps: Sequence[UvBump], pypi: Pypi) -> list[Finding]:
    findings: list[Finding] = []
    for bump in bumps:
        name = bump.new.name
        try:
            version = Version(bump.new.version)
        except InvalidVersion:
            findings.append(Flag("parents", f"{name} {bump.new.version} is not a valid version"))
            continue
        lines: list[tuple[str, str]] = [
            (project, text)
            for project, text in head.project.requirements
            if canonicalize_name(Requirement(text).name) == name
        ]
        for parent in sorted(head.packages.values(), key=lambda p: (p.name, p.version)):
            if name not in parent.dependencies:
                continue
            label = f"{parent.name} {parent.version}"
            if isinstance(parent.source, OtherSource):
                findings.append(
                    Flag(
                        "unchecked",
                        f"{label} depends on {name} but comes from "
                        f"{parent.source.description}; check its range by hand",
                    )
                )
                continue
            release = pypi.release(parent.name, parent.version)
            reqs = [
                r
                for r in (release.requires_dist if release else ())
                if canonicalize_name(r.name) == name
            ]
            if not reqs:
                findings.append(
                    Flag(
                        "parents",
                        f"{label} depends on {name} in the lockfile, but PyPI lists "
                        "no requirement on it",
                    )
                )
            lines += [(label, str(r)) for r in reqs]
        for label, text in sorted(lines):
            if Requirement(text).specifier.contains(version, prereleases=True):
                findings.append(Fact("parents", f"{label} requires {text}"))
            else:
                findings.append(
                    Flag("parents", f"{label} requires {text}, which excludes {bump.new.version}")
                )
    return findings or [Fact("parents", "nothing in the lockfile depends on the bumped packages")]


UV_AUDIT = [
    "uv",
    "audit",
    "--frozen",
    # The project's index settings live in uv's config, and nothing here may contact that index.
    "--no-config",
    "--system-certs",
    "--preview-features",
    "audit-command,json-output",
    "--output-format",
    "json",
]


def uv_audit(side_dir: Path, side: str) -> dict[tuple[str, str], Advisory]:
    """Each advisory, keyed by its alias set's GHSA id (or lowest id) and the package it affects."""
    result = run(UV_AUDIT, side_dir)
    command = f"`{' '.join(UV_AUDIT)}` on the {side}"
    # uv audit exits 1 whenever it finds a vulnerability, so 1 is a result, not a failure.
    if result.returncode not in (0, 1):
        cannot_check(f"{command} failed:\n{result.stderr.strip()}")
    report = parse_json(result.stdout, command)
    schema = report.get("schema") if isinstance(report, dict) else None
    if not isinstance(schema, dict) or schema.get("version") != "preview":
        cannot_check(
            f"{command} returned schema {schema!r}; this script reads the `preview` schema. "
            "uv changed its audit output, so update the script."
        )
    vulnerabilities = report.get("vulnerabilities")
    if not isinstance(vulnerabilities, list):
        cannot_check(f"{command} returned no vulnerabilities list.")

    # One advisory often appears under several ids (a GHSA and a PYSEC), each naming the others.
    groups: list[tuple[set[str], str, list[dict[str, Any]]]] = []
    for v in vulnerabilities:
        dep = v.get("dependency") if isinstance(v, dict) else None
        if not isinstance(dep, dict) or not isinstance(v.get("id"), str):
            cannot_check(f"{command} returned a vulnerability with no id or package: {v!r}.")
        package = canonicalize_name(str(dep.get("name")))
        ids = {v["id"], *[a for a in v.get("aliases") or [] if isinstance(a, str)]}
        for group_ids, group_package, members in groups:
            if group_package == package and group_ids & ids:
                group_ids |= ids
                members.append(v)
                break
        else:
            groups.append((ids, package, [v]))

    advisories: dict[tuple[str, str], Advisory] = {}
    for ids, package, members in groups:
        ghsa = sorted(i for i in ids if i.startswith("GHSA-"))
        canonical = ghsa[0] if ghsa else min(ids)
        main = next((m for m in members if m["id"] == canonical), members[0])
        fixes = ", ".join(main.get("fix_versions") or []) or "no fixed release"
        advisories[(canonical, package)] = Advisory(
            source=0,
            package=package,
            title=main.get("summary") or canonical,
            severity=None,
            vulnerable_range=f"{main['dependency'].get('version')}, fixed in {fixes}",
            url=main.get("link") or "",
        )
    return advisories


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


def check_uv_lockfile(
    snapshot: PrSnapshot, lock_path: str, pypi: Pypi, min_age_days: int
) -> list[Section] | None:
    """The report sections for one uv.lock, or None when it did not change."""
    base = fetch_uv_side(snapshot, lock_path, snapshot.merge_base)
    head = fetch_uv_side(snapshot, lock_path, snapshot.head)
    if head is None:
        return None
    empty = UvLockfile(
        packages={}, project=head.lockfile.project, lowest_python=None, requested_extras={}
    )
    changes = diff_uv_lockfiles(base.lockfile if base else empty, head.lockfile)
    if changes.is_empty():
        return None

    sections: list[Section] = []
    now = datetime.now(UTC)
    checkable: list[UvBump] = []
    for bump in changes.bumps:
        kind = "dev" if bump.new.name in head.lockfile.project.dev else "runtime"
        title = f"{bump.new.name} {bump.old.version} -> {bump.new.version} ({kind})"
        findings: list[Finding] = []
        sources = (bump.old.source, bump.new.source)
        if not all(isinstance(s, PypiSource) for s in sources):
            if bump.old.source != bump.new.source:
                findings.append(
                    Flag(
                        "source",
                        f"changed from {describe_source(bump.old.source)} "
                        f"to {describe_source(bump.new.source)}",
                    )
                )
            elsewhere = describe_source(bump.new.source)
            findings.append(
                Flag(
                    "unchecked",
                    f"{bump.new.name} comes from {elsewhere}, not PyPI; check this release by hand",
                )
            )
            sections.append(Section(title, tuple(findings)))
            continue
        old = pypi.release(bump.old.name, bump.old.version)
        new = pypi.release(bump.new.name, bump.new.version)
        missing = [r for r, found in ((bump.old, old), (bump.new, new)) if found is None]
        if old is None or new is None:
            findings += [
                Flag("release", f"PyPI has no release {p.name} {p.version}") for p in missing
            ]
            sections.append(Section(title, tuple(findings)))
            continue
        old_attested = pypi.attestations(bump.old.name, [f.filename for f in bump.old.files])
        new_attested = pypi.attestations(bump.new.name, [f.filename for f in bump.new.files])
        findings += assess_uv_bump(
            bump, old, new, old_attested, new_attested, head.lockfile, min_age_days, now
        )
        sections.append(Section(title, tuple(findings)))
        checkable.append(bump)

    other: list[Finding] = [
        Flag("altered-entry", f"{a.package.name} {a.package.version} changed {', '.join(a.fields)}")
        for a in changes.altered
    ]
    other += [Flag("added-entry", f"{p.name} {p.version}") for p in changes.added]
    other += [Fact("removed-entry", f"{p.name} {p.version}") for p in changes.removed]
    if other:
        sections.append(Section("Other changes", tuple(other)))

    if changes.bumps:
        sections.append(Section("Parents", tuple(check_parents(head.lockfile, checkable, pypi))))
    with tempfile.TemporaryDirectory() as tmp:
        found: dict[str, dict[tuple[str, str], Advisory]] = {}
        for name, side in (("base", base), ("head", head)):
            if side is None:
                found[name] = {}
                continue
            # uv audit reads the lockfile and the project file from the working directory.
            d = Path(tmp) / name
            d.mkdir()
            (d / "uv.lock").write_text(side.lock_text)
            (d / "pyproject.toml").write_text(side.project_text)
            found[name] = uv_audit(d, name)
    bumped = frozenset(b.new.name for b in changes.bumps)
    advisories = compare_advisories(found["base"], found["head"], bumped)
    sections.append(Section("Advisories", tuple(advisories)))
    return sections


def describe_source(source: PypiSource | OtherSource) -> str:
    match source:
        case PypiSource(index):
            return index
        case OtherSource(description):
            return description


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
    npm_paths = [p for p in snapshot.changed_paths if PurePosixPath(p).name == NPM_LOCKFILE]
    uv_paths = [p for p in snapshot.changed_paths if PurePosixPath(p).name == UV_LOCKFILE]
    unchecked = [p for p in snapshot.changed_paths if PurePosixPath(p).name in UNCHECKED_LOCKFILES]
    if not npm_paths and not uv_paths:
        cannot_check(
            f"{args.repo}#{args.pr} changes no {NPM_LOCKFILE} or {UV_LOCKFILE}, so there is "
            "nothing for this script to check. Check any other lockfile by hand."
        )

    lookups: list[str] = []
    results: list[tuple[str, list[Section]]] = []
    if npm_paths:
        lookups.append(run_ok(["npm", "config", "get", "registry"]).strip())
        registry = Registry()
        for path in npm_paths:
            sections = check_lockfile(snapshot, path, registry, args.min_age_days)
            if sections is not None:
                results.append((path, sections))
    if uv_paths:
        lookups.append(f"{PYPI}/")
        pypi = Pypi()
        for path in uv_paths:
            sections = check_uv_lockfile(snapshot, path, pypi, args.min_age_days)
            if sections is not None:
                results.append((path, sections))
    if not results:
        cannot_check(
            f"Every lockfile this script checks in {args.repo}#{args.pr} is identical at the merge "
            "base and the head, so there is nothing to check."
        )

    lines = [
        f"# Dependency bump check: {args.repo}#{args.pr}",
        "",
        f"Compared head {snapshot.head} with merge base {snapshot.merge_base}. "
        f"Releases looked up in {' and '.join(lookups)}.",
        "",
    ]
    all_findings: list[Finding] = []
    if unchecked:
        not_checked = [
            Flag("unchecked", f"{p} is not a lockfile this script reads; check it by hand")
            for p in unchecked
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
