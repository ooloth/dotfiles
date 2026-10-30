"""Black-box tests for review_dependency_bump.py.

The script runs as a subprocess, never imported, so it stays a single file. Fake `gh`, `npm`, `curl`
and `uv` commands on PATH answer from tables of canned responses and record every call, so no test
reaches GitHub, the npm registry, PyPI or OSV.

Run:
  uv run --with pytest pytest tools/agents/config/skills/review-code/scripts/test_review_dependency_bump.py
"""

import json
import os
import subprocess
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).with_name("review_dependency_bump.py")
REPO = "octo/widgets"
PR = "7"
BASE_TIP = "basetip0000"
MERGE_BASE = "mergebase00"
HEAD = "headsha0000"
LOCK = "frontend/package-lock.json"
MANIFEST = "frontend/package.json"
REGISTRY = "https://registry.npmjs.org/"
LONG_AGO = "2020-01-01T00:00:00.000Z"
UV_LOCK = "backend/uv.lock"
UV_PROJECT = "backend/pyproject.toml"
PYPI = "https://pypi.org"
CURL = "-sS --fail --max-time 30"
SIMPLE_JSON = "-H Accept: application/vnd.pypi.simple.v1+json"
UV_AUDIT = (
    "audit --frozen --no-config --system-certs --preview-features audit-command,json-output "
    "--output-format json"
)
TOOLS = ("gh", "npm", "curl", "uv")
NOT_FOUND = {"stderr": "curl: (22) The requested URL returned error: 404\n", "code": 22}

# Answers each call from a table keyed by its arguments. ls and audit run in a `base` or `head`
# directory, so their keys are prefixed with that directory's name.
FAKE_TOOL = """#!/usr/bin/env python3
import json, os, sys
tool = os.path.basename(sys.argv[0])
args = sys.argv[1:]
with open(os.environ["FAKE_CALLS"], "a") as f:
    f.write(json.dumps([tool, *args]) + "\\n")
table = json.load(open(os.environ["FAKE_" + tool.upper()]))
key = " ".join(args)
reply = table.get(os.path.basename(os.getcwd()) + ": " + key, table.get(key))
if reply is None:
    sys.stderr.write(f"{tool}: no fake response for {key!r}\\n")
    sys.exit(97)
sys.stdout.write(reply.get("stdout", ""))
sys.stderr.write(reply.get("stderr", ""))
sys.exit(reply.get("code", 0))
"""


def entry(version: str, **overrides: Any) -> dict[str, Any]:
    return {
        "version": version,
        "resolved": f"https://registry.npmjs.org/pkg/-/pkg-{version}.tgz",
        "integrity": f"sha512-{version}",
        "dev": True,
        "license": "MIT",
        **overrides,
    }


def lockfile(packages: dict[str, dict[str, Any]], version: int = 3) -> dict[str, Any]:
    return {
        "name": "frontend",
        "lockfileVersion": version,
        "packages": {"": {"name": "frontend"}, **packages},
    }


def release(name: str, version: str, **overrides: Any) -> dict[str, Any]:
    return {
        "name": name,
        "version": version,
        # npm view flattens a person to one "name <email>" string.
        "_npmUser": "maintainer <m@example.com>",
        "scripts": {"test": "tap"},
        "dependencies": {"balanced-match": "^1.0.0"},
        "dist": {
            "integrity": f"sha512-{version}",
            "tarball": f"https://registry.npmjs.org/{name}/-/{name}-{version}.tgz",
        },
        "time": {version: LONG_AGO},
        **overrides,
    }


def audit(*advisories: tuple[str, int, str] | tuple[str, int, str, str]) -> dict[str, Any]:
    """npm audit JSON for (package, advisory id, vulnerable range[, GHSA id]) tuples.

    npm gives each vulnerable range of one GHSA its own advisory id, so two ids can share a GHSA.
    """
    vulns: dict[str, Any] = {}
    for name, source, rng, *rest in advisories:
        ghsa = rest[0] if rest else f"GHSA-{source}"
        vuln = vulns.setdefault(
            name, {"name": name, "severity": "high", "via": [], "nodes": [f"node_modules/{name}"]}
        )
        vuln["via"].append(
            {
                "source": source,
                "name": name,
                "title": f"Advisory {ghsa}",
                "url": f"https://github.com/advisories/{ghsa}",
                "severity": "high",
                "range": rng,
            }
        )
    return {"auditReportVersion": 2, "vulnerabilities": vulns}


def ok(stdout: Any, code: int = 0) -> dict[str, Any]:
    return {"stdout": stdout if isinstance(stdout, str) else json.dumps(stdout), "code": code}


# --- uv.lock and PyPI ----------------------------------------------------------------------------


def toml_value(value: Any) -> str:
    """The TOML subset uv.lock uses: strings, integers, arrays and inline tables."""
    match value:
        case str():
            return json.dumps(value)
        case bool():
            return "true" if value else "false"
        case int():
            return str(value)
        case list():
            return "[" + ", ".join(toml_value(v) for v in value) + "]"
        case dict():
            return "{ " + ", ".join(f'"{k}" = {toml_value(v)}' for k, v in value.items()) + " }"
    raise TypeError(value)


def uv_lock(packages: list[dict[str, Any]], version: int = 1) -> str:
    lines = [f"version = {version}", "revision = 3", 'requires-python = ">=3.13"', ""]
    for package in packages:
        lines.append("[[package]]")
        lines += [f'"{k}" = {toml_value(v)}' for k, v in package.items()]
        lines.append("")
    return "\n".join(lines)


def locked_files(name: str, version: str, wheel: bool = True) -> dict[str, Any]:
    def file(filename: str) -> dict[str, Any]:
        return {
            "url": f"https://files.pythonhosted.org/packages/ab/{filename}",
            "hash": f"sha256:{filename}",
            "size": 100,
            "upload-time": LONG_AGO,
        }

    files: dict[str, Any] = {"sdist": file(f"{name}-{version}.tar.gz")}
    if wheel:
        files["wheels"] = [file(f"{name}-{version}-py3-none-any.whl")]
    return files


def uv_package(name: str, version: str, wheel: bool = True, **overrides: Any) -> dict[str, Any]:
    return {
        "name": name,
        "version": version,
        "source": {"registry": "https://pypi.org/simple"},
        **locked_files(name, version, wheel),
        **overrides,
    }


def project(requires_lib: str = ">=1") -> dict[str, Any]:
    """The project itself: lib reached at runtime through mid, tool from a dev group."""
    return {
        "name": "app",
        "version": "0.1.0",
        "source": {"virtual": "."},
        "dependencies": [{"name": "mid"}],
        "dev-dependencies": {"dev": [{"name": "tool"}, {"name": "lib"}]},
        "metadata": {
            "requires-dist": [{"name": "mid", "specifier": ">=2"}],
            "requires-dev": {"dev": [{"name": "tool"}, {"name": "lib", "specifier": requires_lib}]},
        },
    }


def lib_lock(lib_version: str, wheel: bool = True, **lib_overrides: Any) -> list[dict[str, Any]]:
    return [
        project(),
        uv_package("mid", "2.0.0", dependencies=[{"name": "lib"}]),
        uv_package("lib", lib_version, wheel, **lib_overrides),
        uv_package("tool", "3.0.0"),
    ]


def pypi_release(name: str, version: str, wheel: bool = True, **info: Any) -> dict[str, Any]:
    """PyPI's JSON for one release, with the files locked_files() locks."""
    filenames = [f"{name}-{version}.tar.gz"]
    if wheel:
        filenames.append(f"{name}-{version}-py3-none-any.whl")
    return {
        "info": {"requires_dist": None, "requires_python": ">=3.9", **info},
        "urls": [
            {
                "filename": f,
                "digests": {"sha256": f},
                "yanked": False,
                "yanked_reason": None,
                "upload_time_iso_8601": LONG_AGO,
            }
            for f in filenames
        ],
    }


PUBLISHER = {
    "kind": "GitHub",
    "repository": "octo/lib",
    "workflow": "release.yml",
    "environment": "pypi",
}


def provenance(publisher: dict[str, Any]) -> dict[str, Any]:
    return {"attestation_bundles": [{"publisher": publisher, "attestations": []}]}


def uv_audit(*vulnerabilities: tuple[str, str, str] | tuple[str, str, str, list[str]]) -> Any:
    """uv audit JSON for (package, version, id[, aliases]) tuples."""
    entries = []
    for name, version, id_, *rest in vulnerabilities:
        entries.append(
            {
                "dependency": {"name": name, "version": version},
                "id": id_,
                "display_id": id_,
                "aliases": rest[0] if rest else [],
                "summary": f"Advisory {id_}",
                "description": "",
                "link": f"https://osv.dev/vulnerability/{id_}",
                "fix_versions": ["1.0.1"],
                "published": LONG_AGO,
                "modified": LONG_AGO,
            }
        )
    return {
        "schema": {"version": "preview"},
        "summary": {"audited_packages": 4, "vulnerabilities": len(entries), "adverse_statuses": 0},
        "vulnerabilities": entries,
        "adverse_statuses": [],
    }


class Scenario:
    """One PR that bumps pkg 1.0.0 to 1.0.1 cleanly. Each test changes the part it is about.

    It also holds a uv.lock that bumps lib 1.0.0 to 1.0.1 cleanly, which a test reaches by putting
    UV_LOCK in `files`.
    """

    def __init__(self, tmp_path: Path, fake_bin: Path) -> None:
        self.fake_bin = fake_bin
        self.uv_base: list[dict[str, Any]] | None = lib_lock("1.0.0")
        self.uv_head: list[dict[str, Any]] = lib_lock("1.0.1")
        self.pypi = {
            ("lib", "1.0.0"): pypi_release("lib", "1.0.0"),
            ("lib", "1.0.1"): pypi_release("lib", "1.0.1"),
            ("mid", "2.0.0"): pypi_release("mid", "2.0.0", requires_dist=["lib>=1.0"]),
        }
        # Each locked file's attestation publisher, or None for a file with none.
        self.attested: dict[str, dict[str, Any] | None] = {
            f: PUBLISHER
            for v in ("1.0.0", "1.0.1")
            for f in (f"lib-{v}.tar.gz", f"lib-{v}-py3-none-any.whl")
        }
        self.uv_base_audit = uv_audit(
            ("lib", "1.0.0", "GHSA-201", ["PYSEC-201"]), ("lib", "1.0.0", "PYSEC-201", ["GHSA-201"])
        )
        self.uv_head_audit = uv_audit()
        self.curl_overrides: dict[str, Any] = {}
        self.uv_overrides: dict[str, Any] = {}
        self.tmp_path = tmp_path
        self.files = [LOCK]
        self.base_lock: dict[str, Any] | None = lockfile({"node_modules/pkg": entry("1.0.0")})
        self.head_lock: dict[str, Any] = lockfile({"node_modules/pkg": entry("1.0.1")})
        self.releases = {
            ("pkg", "1.0.0"): release("pkg", "1.0.0"),
            ("pkg", "1.0.1"): release("pkg", "1.0.1"),
        }
        self.base_audit = audit(("pkg", 101, "<1.0.1"))
        self.head_audit = audit()
        self.ls: dict[str, Any] = ok({"name": "frontend"})
        self.gh_overrides: dict[str, Any] = {}
        self.npm_overrides: dict[str, Any] = {}

    def gh_table(self) -> dict[str, Any]:
        def contents(path: str, sha: str) -> str:
            return (
                f"api -H Accept: application/vnd.github.raw repos/{REPO}/contents/{path}?ref={sha}"
            )

        missing = {"stderr": "gh: Not Found (HTTP 404)\n", "code": 1}
        table = {
            f"pr view {PR} -R {REPO} --json baseRefName,headRefOid": ok(
                {"baseRefName": "trunk", "headRefOid": HEAD}
            ),
            f"api --paginate repos/{REPO}/pulls/{PR}/files -q .[].filename": ok(
                "".join(f"{f}\n" for f in self.files)
            ),
            f"api repos/{REPO}/compare/trunk...{HEAD} -q .merge_base_commit.sha": ok(
                f"{MERGE_BASE}\n"
            ),
            contents(LOCK, HEAD): ok(self.head_lock),
            contents(MANIFEST, HEAD): ok({"name": "frontend"}),
            contents(LOCK, MERGE_BASE): ok(self.base_lock) if self.base_lock else missing,
            contents(MANIFEST, MERGE_BASE): ok({"name": "frontend"}) if self.base_lock else missing,
            contents(UV_LOCK, HEAD): ok(uv_lock(self.uv_head)),
            contents(UV_PROJECT, HEAD): ok('[project]\nname = "app"\n'),
            contents(UV_LOCK, MERGE_BASE): ok(uv_lock(self.uv_base)) if self.uv_base else missing,
            contents(UV_PROJECT, MERGE_BASE): ok('[project]\nname = "app"\n')
            if self.uv_base
            else missing,
        }
        return {**table, **self.gh_overrides}

    def curl_table(self) -> dict[str, Any]:
        table: dict[str, Any] = {}
        for (name, version), doc in self.pypi.items():
            table[f"{CURL} {PYPI}/pypi/{name}/{version}/json"] = ok(doc)
        files = []
        for filename, publisher in self.attested.items():
            url = f"{PYPI}/integrity/lib/{filename}/provenance" if publisher else None
            files.append({"filename": filename, "provenance": url})
            if publisher:
                table[f"{CURL} {url}"] = ok(provenance(publisher))
        table[f"{CURL} {SIMPLE_JSON} {PYPI}/simple/lib/"] = ok({"files": files})
        return {**table, **self.curl_overrides}

    def uv_table(self) -> dict[str, Any]:
        table = {
            f"{side}: {UV_AUDIT}": ok(report, code=1 if report["vulnerabilities"] else 0)
            for side, report in (("base", self.uv_base_audit), ("head", self.uv_head_audit))
        }
        return {**table, **self.uv_overrides}

    def npm_table(self) -> dict[str, Any]:
        table: dict[str, Any] = {
            "config get registry": ok(f"{REGISTRY}\n"),
            "head: ls --all --package-lock-only --json": self.ls,
            "base: audit --package-lock-only --json": ok(self.base_audit),
            "head: audit --package-lock-only --json": ok(self.head_audit),
        }
        for (name, version), doc in self.releases.items():
            # npm view wraps a single match in a list on some versions; the script accepts both.
            table[f"view {name}@{version} --json"] = ok([doc])
        return {**table, **self.npm_overrides}

    def run(self, *extra: str) -> subprocess.CompletedProcess[str]:
        tables = {
            "gh": self.gh_table(),
            "npm": self.npm_table(),
            "curl": self.curl_table(),
            "uv": self.uv_table(),
        }
        env = {
            **os.environ,
            "PATH": f"{self.fake_bin}{os.pathsep}{os.environ['PATH']}",
            "FAKE_CALLS": str(self.calls_file),
        }
        for tool, table in tables.items():
            (self.tmp_path / f"{tool}.json").write_text(json.dumps(table))
            env[f"FAKE_{tool.upper()}"] = str(self.tmp_path / f"{tool}.json")
        return subprocess.run(
            [sys.executable, str(SCRIPT), PR, "--repo", REPO, *extra],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )

    @property
    def calls_file(self) -> Path:
        return self.tmp_path / "calls"

    def calls(self) -> list[list[str]]:
        if not self.calls_file.exists():
            return []
        return [json.loads(line) for line in self.calls_file.read_text().splitlines()]


@pytest.fixture(scope="module")
def fake_bin(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """The fake tools, written once for the module and then made read-only. Each test's tables and
    call log live in its own tmp_path, so the tools are the same for every test, and a newly written
    executable is slow to start the first time on a Mac running endpoint security."""
    folder = tmp_path_factory.mktemp("bin")
    for tool in TOOLS:
        path = folder / tool
        path.write_text(FAKE_TOOL)
        path.chmod(0o755)
    folder.chmod(0o555)
    return folder


def test_a_fake_tool_cannot_write_beside_itself_in_the_shared_folder(fake_bin: Path) -> None:
    with pytest.raises(PermissionError):
        (fake_bin / "written-by-a-test").write_text("x")


@pytest.fixture
def s(tmp_path: Path, fake_bin: Path) -> Scenario:
    return Scenario(tmp_path, fake_bin)


def flags(result: subprocess.CompletedProcess[str]) -> list[str]:
    return [line for line in result.stdout.splitlines() if line.startswith("- FLAG ")]


def assert_flagged(result: subprocess.CompletedProcess[str], check: str) -> None:
    assert result.returncode == 1, result.stdout + result.stderr
    assert any(f.startswith(f"- FLAG {check}:") for f in flags(result)), result.stdout


# --- The clean case ---------------------------------------------------------------------------

GOLDEN_CLEAN = """\
# Dependency bump check: octo/widgets#7

Compared head headsha0000 with merge base mergebase00. Releases looked up in https://registry.npmjs.org/.

## frontend/package-lock.json

### pkg 1.0.0 -> 1.0.1 (dev) at node_modules/pkg
- integrity: matches the registry
- resolved-host: registry.npmjs.org (unchanged)
- publisher: maintainer <m@example.com> (unchanged)
- install-scripts: none
- dependencies: unchanged
- engines: unchanged
- provenance: absent on both releases
- age: published 2020-01-01

### Tree
- tree: npm ls reports no problems

### Advisories
- advisories: fixed Advisory GHSA-101 (high) in pkg <1.0.1, https://github.com/advisories/GHSA-101

0 flags.
"""


def test_a_clean_bump_reports_every_check_and_the_advisory_it_fixes(s: Scenario) -> None:
    result = s.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout == GOLDEN_CLEAN


def test_releases_are_compared_against_the_merge_base_not_the_base_branch_tip(
    s: Scenario,
) -> None:
    s.run()
    fetched = [c[-1] for c in s.calls() if c[0] == "gh" and "/contents/" in c[-1]]
    assert any(f.endswith(f"?ref={MERGE_BASE}") for f in fetched)
    assert not any(BASE_TIP in f or "ref=trunk" in f for f in fetched)


def test_no_gh_call_writes_anything(s: Scenario) -> None:
    assert s.run().returncode == 0
    gh_args = [arg for c in s.calls() if c[0] == "gh" for arg in c]
    assert gh_args, "the script made no gh calls, so this test checked nothing"
    for writer in ("--method", "-X", "--input", "-f", "-F", "--field", "--raw-field", "comment"):
        assert writer not in gh_args


# --- Signs of a compromised publish --------------------------------------------------------------


def test_a_different_publisher_is_flagged(s: Scenario) -> None:
    s.releases["pkg", "1.0.1"]["_npmUser"] = "stranger <s@example.com>"
    assert_flagged(s.run(), "publisher")


def test_the_same_publisher_with_a_different_email_is_flagged(s: Scenario) -> None:
    s.releases["pkg", "1.0.1"]["_npmUser"] = "maintainer <new@example.com>"
    assert_flagged(s.run(), "publisher")


@pytest.mark.parametrize("hook", ["preinstall", "install", "postinstall"])
def test_an_added_install_script_is_flagged(s: Scenario, hook: str) -> None:
    s.releases["pkg", "1.0.1"]["scripts"] = {"test": "tap", hook: "node setup.js"}
    assert_flagged(s.run(), "install-scripts")


def test_a_script_that_never_runs_on_install_is_not_flagged(s: Scenario) -> None:
    s.releases["pkg", "1.0.1"]["scripts"] = {"test": "tap", "prepare": "tshy"}
    result = s.run()
    assert result.returncode == 0
    assert "- install-scripts: none" in result.stdout


def test_a_lockfile_entry_that_gains_an_install_script_is_flagged(s: Scenario) -> None:
    s.head_lock["packages"]["node_modules/pkg"]["hasInstallScript"] = True
    assert_flagged(s.run(), "install-scripts")


def test_a_dependency_added_by_the_new_release_is_flagged(s: Scenario) -> None:
    s.releases["pkg", "1.0.1"]["dependencies"] = {"balanced-match": "^1.0.0", "evil": "1.0.0"}
    result = s.run()
    assert_flagged(result, "dependencies")
    assert "evil" in result.stdout


def test_provenance_the_old_release_had_and_the_new_one_lacks_is_flagged(s: Scenario) -> None:
    s.releases["pkg", "1.0.0"]["dist"]["attestations"] = {"provenance": {"predicateType": "x"}}
    assert_flagged(s.run(), "provenance")


def test_provenance_on_the_new_release_is_reported_without_a_flag(s: Scenario) -> None:
    s.releases["pkg", "1.0.1"]["dist"]["attestations"] = {"provenance": {"predicateType": "x"}}
    result = s.run()
    assert result.returncode == 0
    assert "- provenance: present on the new release" in result.stdout


def test_changed_engines_are_flagged(s: Scenario) -> None:
    s.releases["pkg", "1.0.1"]["engines"] = {"node": ">=22"}
    assert_flagged(s.run(), "engines")


def test_a_release_younger_than_the_threshold_is_flagged(s: Scenario) -> None:
    yesterday = (datetime.now(UTC) - timedelta(days=1)).isoformat()
    s.releases["pkg", "1.0.1"]["time"] = {"1.0.1": yesterday}
    assert_flagged(s.run(), "age")


def test_the_age_threshold_can_be_lowered(s: Scenario) -> None:
    three_days_ago = (datetime.now(UTC) - timedelta(days=3)).isoformat()
    s.releases["pkg", "1.0.1"]["time"] = {"1.0.1": three_days_ago}
    assert s.run().returncode == 1
    assert s.run("--min-age-days", "2").returncode == 0


# --- Lockfile tampering --------------------------------------------------------------------------


def test_a_lockfile_hash_that_differs_from_the_registry_is_flagged(s: Scenario) -> None:
    s.head_lock["packages"]["node_modules/pkg"]["integrity"] = "sha512-tampered"
    assert_flagged(s.run(), "integrity")


def test_a_resolved_host_that_changed_since_the_base_is_flagged(s: Scenario) -> None:
    s.head_lock["packages"]["node_modules/pkg"]["resolved"] = "https://evil.example/pkg-1.0.1.tgz"
    assert_flagged(s.run(), "resolved-host")


def test_a_hash_and_url_the_lockfile_drops_are_flagged(s: Scenario) -> None:
    del s.head_lock["packages"]["node_modules/pkg"]["integrity"]
    del s.head_lock["packages"]["node_modules/pkg"]["resolved"]
    result = s.run()
    assert_flagged(result, "integrity")
    assert_flagged(result, "resolved-host")


def test_an_entry_that_never_recorded_a_hash_or_url_is_reported_without_a_flag(
    s: Scenario,
) -> None:
    # npm leaves both out of some entries; the PR did not remove them.
    for lock in (s.base_lock or {}, s.head_lock):
        del lock["packages"]["node_modules/pkg"]["integrity"]
        del lock["packages"]["node_modules/pkg"]["resolved"]
    result = s.run()
    assert result.returncode == 0, result.stdout
    assert "- integrity: the lockfile records no hash for this entry, before or after" in (
        result.stdout
    )
    assert "- resolved-host: the lockfile records no URL for this entry, before or after" in (
        result.stdout
    )


def test_an_entry_altered_without_a_version_change_is_flagged(s: Scenario) -> None:
    s.base_lock = lockfile(
        {"node_modules/pkg": entry("1.0.0"), "node_modules/other": entry("2.0.0")}
    )
    s.head_lock = lockfile(
        {
            "node_modules/pkg": entry("1.0.1"),
            "node_modules/other": entry("2.0.0", integrity="sha512-swapped"),
        }
    )
    result = s.run()
    assert_flagged(result, "altered-entry")
    assert "node_modules/other" in result.stdout
    assert "integrity" in result.stdout


def test_added_and_removed_entries_are_listed(s: Scenario) -> None:
    s.base_lock = lockfile(
        {"node_modules/pkg": entry("1.0.0"), "node_modules/gone": entry("1.0.0")}
    )
    s.head_lock = lockfile({"node_modules/pkg": entry("1.0.1"), "node_modules/new": entry("3.0.0")})
    result = s.run()
    assert "- FLAG added-entry: node_modules/new 3.0.0" in result.stdout
    assert "- removed-entry: node_modules/gone 1.0.0" in result.stdout


# --- Range questions npm answers -----------------------------------------------------------------


def test_a_problem_npm_ls_reports_on_the_head_is_flagged(s: Scenario) -> None:
    s.ls = ok({"name": "frontend", "problems": ["invalid: pkg@1.0.1 node_modules/pkg"]}, code=1)
    result = s.run()
    assert_flagged(result, "tree")
    assert "invalid: pkg@1.0.1" in result.stdout


def test_an_advisory_the_head_has_and_the_base_lacked_is_flagged(s: Scenario) -> None:
    s.head_audit = audit(("pkg", 202, ">=1.0.1"))
    result = s.run()
    assert_flagged(result, "advisories")
    assert "introduced Advisory GHSA-202" in result.stdout


def test_a_bumped_package_still_matched_by_an_advisory_is_flagged(s: Scenario) -> None:
    s.base_audit = audit(("pkg", 101, "<2.0.0"))
    s.head_audit = audit(("pkg", 101, "<2.0.0"))
    result = s.run()
    assert_flagged(result, "advisories")
    assert "still affected by Advisory GHSA-101" in result.stdout


def test_the_ranges_of_one_advisory_are_reported_on_one_line(s: Scenario) -> None:
    s.base_audit = audit(("pkg", 101, "<1.0.1", "GHSA-x"), ("pkg", 102, ">=4.0.0 <4.0.5", "GHSA-x"))
    result = s.run()
    fixed = [line for line in result.stdout.splitlines() if "fixed" in line]
    assert fixed == [
        "- advisories: fixed Advisory GHSA-x (high) in pkg <1.0.1 and >=4.0.0 <4.0.5, "
        "https://github.com/advisories/GHSA-x"
    ]


def test_an_advisory_fixed_on_one_range_and_not_another_is_flagged(s: Scenario) -> None:
    s.base_audit = audit(("pkg", 101, "<1.0.1", "GHSA-x"), ("pkg", 102, "<2.0.0", "GHSA-x"))
    s.head_audit = audit(("pkg", 102, "<2.0.0", "GHSA-x"))
    result = s.run()
    assert_flagged(result, "advisories")
    assert "still affected by Advisory GHSA-x (high) in pkg <2.0.0" in result.stdout


def test_advisories_are_counted_once_per_ghsa(s: Scenario) -> None:
    s.base_audit = audit(
        ("pkg", 101, "<1.0.1"), ("other", 303, "<9", "GHSA-y"), ("other", 304, ">=10 <11", "GHSA-y")
    )
    s.head_audit = audit(("other", 303, "<9", "GHSA-y"), ("other", 304, ">=10 <11", "GHSA-y"))
    assert "1 advisory affects packages this PR does not change" in s.run().stdout


def test_advisories_on_untouched_packages_are_counted_without_a_flag(s: Scenario) -> None:
    s.base_audit = audit(("pkg", 101, "<1.0.1"), ("other", 303, "<9"))
    s.head_audit = audit(("other", 303, "<9"))
    result = s.run()
    assert result.returncode == 0
    assert "1 advisory affects packages this PR does not change" in result.stdout


# --- Nothing to check, or a check that could not run --------------------------------------------


def test_a_pr_without_a_lockfile_it_checks_exits_2(s: Scenario) -> None:
    s.files = ["backend/poetry.lock"]
    result = s.run()
    assert result.returncode == 2
    assert "package-lock.json" in result.stderr and "uv.lock" in result.stderr
    assert result.stdout == ""


def test_identical_lockfiles_exit_2(s: Scenario) -> None:
    s.head_lock = s.base_lock or {}
    result = s.run()
    assert result.returncode == 2
    assert "nothing to check" in result.stderr


def test_a_lockfile_beside_the_npm_one_is_flagged_as_unchecked(s: Scenario) -> None:
    s.files = [LOCK, "backend/poetry.lock"]
    result = s.run()
    assert_flagged(result, "unchecked")
    assert "backend/poetry.lock" in result.stdout


def test_a_new_lockfile_reports_every_entry_as_added(s: Scenario) -> None:
    s.base_lock = None
    result = s.run()
    assert "- FLAG added-entry: node_modules/pkg 1.0.1" in result.stdout


def test_a_failing_gh_call_exits_2_and_names_the_command(s: Scenario) -> None:
    s.gh_overrides[f"api repos/{REPO}/compare/trunk...{HEAD} -q .merge_base_commit.sha"] = {
        "stderr": "HTTP 502\n",
        "code": 1,
    }
    result = s.run()
    assert result.returncode == 2
    assert "gh api" in result.stderr and "compare" in result.stderr and "HTTP 502" in result.stderr
    assert result.stdout == ""


def test_a_failing_npm_view_exits_2_and_names_the_release(s: Scenario) -> None:
    s.npm_overrides["view pkg@1.0.1 --json"] = {"stderr": "E404\n", "code": 1}
    result = s.run()
    assert result.returncode == 2
    assert "pkg@1.0.1" in result.stderr and "E404" in result.stderr
    assert result.stdout == ""


def test_an_audit_that_errors_exits_2(s: Scenario) -> None:
    s.npm_overrides["head: audit --package-lock-only --json"] = ok(
        {"error": {"code": "ENOTFOUND", "summary": "network"}}, code=1
    )
    result = s.run()
    assert result.returncode == 2
    assert "audit" in result.stderr


def test_a_version_1_lockfile_exits_2(s: Scenario) -> None:
    s.head_lock = {"name": "frontend", "lockfileVersion": 1, "dependencies": {}}
    result = s.run()
    assert result.returncode == 2
    assert "lockfileVersion 1" in result.stderr


# --- uv.lock: the clean case ---------------------------------------------------------------------

GOLDEN_UV_CLEAN = """\
# Dependency bump check: octo/widgets#7

Compared head headsha0000 with merge base mergebase00. Releases looked up in https://pypi.org/.

## backend/uv.lock

### lib 1.0.0 -> 1.0.1 (runtime)
- hashes: 2 locked files match PyPI
- source: pypi.org (unchanged)
- publisher: GitHub octo/lib release.yml (pypi) (unchanged)
- provenance: 2 of 2 locked files attested (old release: 2 of 2)
- dependencies: unchanged
- python: unchanged (>=3.9)
- yanked: none
- wheels: 1 wheel and an sdist
- age: uploaded 2020-01-01

### Parents
- parents: app requires lib>=1
- parents: mid 2.0.0 requires lib>=1.0

### Advisories
- advisories: fixed Advisory GHSA-201 in lib 1.0.0, fixed in 1.0.1, https://osv.dev/vulnerability/GHSA-201

0 flags.
"""


@pytest.fixture
def u(tmp_path: Path, fake_bin: Path) -> Scenario:
    scenario = Scenario(tmp_path, fake_bin)
    scenario.files = [UV_LOCK]
    return scenario


def lib(lock: list[dict[str, Any]]) -> dict[str, Any]:
    return next(p for p in lock if p["name"] == "lib")


def test_a_clean_uv_bump_reports_every_check_its_parents_and_the_advisory_it_fixes(
    u: Scenario,
) -> None:
    result = u.run()
    assert result.returncode == 0, result.stderr
    assert result.stdout == GOLDEN_UV_CLEAN


def test_a_package_reached_only_from_a_dev_group_is_labelled_dev(u: Scenario) -> None:
    u.uv_base = [
        project(),
        uv_package("mid", "2.0.0", dependencies=[{"name": "lib"}]),
        uv_package("lib", "1.0.1"),
        uv_package("tool", "3.0.0"),
    ]
    u.uv_head = [*u.uv_base[:3], uv_package("tool", "3.0.1")]
    u.pypi["tool", "3.0.0"] = pypi_release("tool", "3.0.0")
    u.pypi["tool", "3.0.1"] = pypi_release("tool", "3.0.1")
    u.curl_overrides[f"{CURL} {SIMPLE_JSON} {PYPI}/simple/tool/"] = ok({"files": []})
    u.uv_base_audit = uv_audit()
    result = u.run()
    assert "### tool 3.0.0 -> 3.0.1 (dev)" in result.stdout, result.stdout + result.stderr


def test_both_lockfiles_are_reported_when_a_pr_changes_both(u: Scenario) -> None:
    u.files = [LOCK, UV_LOCK, "backend/poetry.lock"]
    result = u.run()
    assert "## frontend/package-lock.json" in result.stdout, result.stderr
    assert "## backend/uv.lock" in result.stdout
    assert "Releases looked up in https://registry.npmjs.org/ and https://pypi.org/." in (
        result.stdout
    )
    assert "- FLAG unchecked: backend/poetry.lock" in result.stdout


# --- uv.lock: signs of a compromised publish -----------------------------------------------------


def test_a_locked_hash_that_differs_from_pypi_is_flagged(u: Scenario) -> None:
    lib(u.uv_head)["wheels"][0]["hash"] = "sha256:tampered"
    result = u.run()
    assert_flagged(result, "hashes")
    assert "lib-1.0.1-py3-none-any.whl" in result.stdout


def test_a_locked_file_pypi_does_not_list_is_flagged(u: Scenario) -> None:
    lib(u.uv_head)["wheels"].append(
        {
            "url": "https://files.pythonhosted.org/packages/ab/lib-1.0.1-extra.whl",
            "hash": "sha256:x",
            "size": 1,
            "upload-time": LONG_AGO,
        }
    )
    result = u.run()
    assert_flagged(result, "hashes")
    assert "lib-1.0.1-extra.whl" in result.stdout


def test_a_locked_release_pypi_does_not_have_is_flagged(u: Scenario) -> None:
    u.curl_overrides[f"{CURL} {PYPI}/pypi/lib/1.0.1/json"] = NOT_FOUND
    result = u.run()
    assert_flagged(result, "release")
    assert "lib 1.0.1" in result.stdout


def test_a_registry_source_that_changed_is_flagged(u: Scenario) -> None:
    lib(u.uv_head)["source"] = {"registry": "https://evil.example/simple"}
    result = u.run()
    assert_flagged(result, "source")
    assert_flagged(result, "unchecked")


def test_a_package_from_another_index_is_never_looked_up_there(u: Scenario) -> None:
    for lock in (u.uv_base or [], u.uv_head):
        lib(lock)["source"] = {"registry": "https://private.example/simple"}
    result = u.run()
    assert_flagged(result, "unchecked")
    assert "private.example" in result.stdout
    urls = [c[-1] for c in u.calls() if c[0] == "curl"]
    assert not any("private.example" in url for url in urls)


def test_a_different_publisher_is_flagged_on_pypi(u: Scenario) -> None:
    for f in ("lib-1.0.1.tar.gz", "lib-1.0.1-py3-none-any.whl"):
        u.attested[f] = {**PUBLISHER, "repository": "stranger/lib"}
    result = u.run()
    assert_flagged(result, "publisher")
    assert "stranger/lib" in result.stdout


def test_a_release_with_fewer_attested_files_is_flagged(u: Scenario) -> None:
    u.attested["lib-1.0.1-py3-none-any.whl"] = None
    result = u.run()
    assert_flagged(result, "provenance")
    assert "1 of 2" in result.stdout


def test_releases_without_attestations_are_reported_without_a_flag(u: Scenario) -> None:
    u.attested = dict.fromkeys(u.attested)
    result = u.run()
    assert result.returncode == 0, result.stdout
    assert "- publisher: PyPI names no publisher; neither release has attestations" in (
        result.stdout
    )


def test_a_requirement_the_new_release_adds_is_flagged(u: Scenario) -> None:
    u.pypi["lib", "1.0.1"]["info"]["requires_dist"] = ["evil>=1; python_version >= '3'"]
    result = u.run()
    assert_flagged(result, "dependencies")
    assert "evil" in result.stdout


def test_a_requirement_under_an_extra_nothing_requests_is_reported_without_a_flag(
    u: Scenario,
) -> None:
    # Pillow 13.0.0's own marker: a platform choice that only applies under the extra.
    u.pypi["lib", "1.0.1"]["info"]["requires_dist"] = [
        'psutil; (sys_platform == "linux" or sys_platform == "darwin") and extra == "tests"'
    ]
    result = u.run()
    assert result.returncode == 0, result.stdout
    assert (
        "- dependencies: the new release adds psutil under the tests extra, which nothing in "
        "the lockfile requests"
    ) in result.stdout


def test_a_requirement_under_an_extra_the_lockfile_requests_is_flagged(u: Scenario) -> None:
    u.uv_head[1] = uv_package("mid", "2.0.0", dependencies=[{"name": "lib", "extra": ["cli"]}])
    u.pypi["lib", "1.0.1"]["info"]["requires_dist"] = ['click; extra == "cli"']
    result = u.run()
    assert_flagged(result, "dependencies")
    assert "click" in result.stdout


def test_a_requirement_an_extra_gates_only_partly_is_flagged(u: Scenario) -> None:
    # `and` binds tighter than `or`, so this installs on Linux without the extra.
    u.pypi["lib", "1.0.1"]["info"]["requires_dist"] = [
        'evil; sys_platform == "linux" or python_version >= "3" and extra == "tests"'
    ]
    assert_flagged(u.run(), "dependencies")


def test_a_requires_python_that_excludes_the_projects_lowest_python_is_flagged(
    u: Scenario,
) -> None:
    u.pypi["lib", "1.0.1"]["info"]["requires_python"] = ">=3.14"
    result = u.run()
    assert_flagged(result, "python")
    assert "excludes Python 3.13" in result.stdout


def test_a_requires_python_that_still_allows_the_projects_lowest_python_is_not_flagged(
    u: Scenario,
) -> None:
    u.pypi["lib", "1.0.1"]["info"]["requires_python"] = ">=3.11"
    result = u.run()
    assert result.returncode == 0, result.stdout
    assert (
        "- python: changed from >=3.9 to >=3.11, which still allows Python 3.13, the lowest "
        "this project supports"
    ) in result.stdout


def test_a_yanked_locked_file_is_flagged(u: Scenario) -> None:
    u.pypi["lib", "1.0.1"]["urls"][0].update(yanked=True, yanked_reason="broken build")
    result = u.run()
    assert_flagged(result, "yanked")
    assert "broken build" in result.stdout


def test_a_release_that_locks_no_wheel_where_the_old_one_did_is_flagged(u: Scenario) -> None:
    u.uv_head = lib_lock("1.0.1", wheel=False)
    u.pypi["lib", "1.0.1"] = pypi_release("lib", "1.0.1", wheel=False)
    assert_flagged(u.run(), "wheels")


def test_a_file_uploaded_inside_the_threshold_is_flagged(u: Scenario) -> None:
    yesterday = (datetime.now(UTC) - timedelta(days=1)).isoformat()
    u.pypi["lib", "1.0.1"]["urls"][1]["upload_time_iso_8601"] = yesterday
    assert_flagged(u.run(), "age")


# --- uv.lock: parents and tampering --------------------------------------------------------------


def test_a_parent_on_pypi_whose_range_excludes_the_new_version_is_flagged(u: Scenario) -> None:
    u.pypi["mid", "2.0.0"]["info"]["requires_dist"] = ["lib<1.0.1"]
    result = u.run()
    assert_flagged(result, "parents")
    assert "mid 2.0.0 requires lib<1.0.1" in result.stdout


def test_the_projects_own_range_that_excludes_the_new_version_is_flagged(u: Scenario) -> None:
    u.uv_head[0] = project(requires_lib="==1.0.0")
    result = u.run()
    assert_flagged(result, "parents")
    assert "app requires lib==1.0.0" in result.stdout


def test_a_package_altered_without_a_version_change_is_flagged(u: Scenario) -> None:
    next(p for p in u.uv_head if p["name"] == "tool")["sdist"]["hash"] = "sha256:swapped"
    result = u.run()
    assert_flagged(result, "altered-entry")
    assert "tool" in result.stdout


def test_added_and_removed_packages_are_listed(u: Scenario) -> None:
    u.uv_base = [*lib_lock("1.0.0"), uv_package("gone", "1.0.0")]
    u.uv_head = [*lib_lock("1.0.1"), uv_package("new", "3.0.0")]
    result = u.run()
    assert "- FLAG added-entry: new 3.0.0" in result.stdout
    assert "- removed-entry: gone 1.0.0" in result.stdout


def test_a_name_locked_at_two_versions_is_listed_as_added_and_removed(u: Scenario) -> None:
    u.uv_head = [*lib_lock("1.0.1"), uv_package("lib", "0.9.0")]
    result = u.run()
    assert "- FLAG added-entry: lib 1.0.1" in result.stdout
    assert "- FLAG added-entry: lib 0.9.0" in result.stdout
    assert "- removed-entry: lib 1.0.0" in result.stdout


# --- uv.lock: advisories -------------------------------------------------------------------------


def test_an_advisory_the_uv_head_has_and_the_base_lacked_is_flagged(u: Scenario) -> None:
    u.uv_head_audit = uv_audit(("lib", "1.0.1", "GHSA-202"))
    result = u.run()
    assert_flagged(result, "advisories")
    assert "introduced Advisory GHSA-202" in result.stdout


def test_a_bumped_uv_package_still_affected_is_flagged(u: Scenario) -> None:
    # The head reports it under its PYSEC id; it is still the advisory the base had.
    u.uv_head_audit = uv_audit(("lib", "1.0.1", "PYSEC-201", ["GHSA-201"]))
    result = u.run()
    assert_flagged(result, "advisories")
    assert "still affected by Advisory PYSEC-201 in lib 1.0.1" in result.stdout
    assert "introduced" not in result.stdout


def test_aliases_of_one_advisory_count_once(u: Scenario) -> None:
    both = (("tool", "3.0.0", "GHSA-9", ["PYSEC-9"]), ("tool", "3.0.0", "PYSEC-9", ["GHSA-9"]))
    u.uv_base_audit = uv_audit(*both)
    u.uv_head_audit = uv_audit(*both)
    result = u.run()
    assert "1 advisory affects packages this PR does not change" in result.stdout


# --- uv.lock: what is contacted, and checks that could not run -----------------------------------


def test_uv_runs_without_the_projects_index_config_and_with_system_certificates(
    u: Scenario,
) -> None:
    assert u.run().returncode == 0
    audits = [c for c in u.calls() if c[0] == "uv"]
    assert len(audits) == 2
    assert all("--no-config" in c and "--system-certs" in c for c in audits)
    hosts = {c[-1].split("/")[2] for c in u.calls() if c[0] == "curl"}
    assert hosts == {"pypi.org"}


def test_no_curl_call_writes_anything(u: Scenario) -> None:
    assert u.run().returncode == 0
    curl_args = [arg for c in u.calls() if c[0] == "curl" for arg in c]
    assert curl_args, "the script made no curl calls, so this test checked nothing"
    for writer in ("-X", "--request", "-d", "--data", "-F", "--form", "-T", "--upload-file"):
        assert writer not in curl_args


def test_a_uv_lockfile_of_another_version_exits_2(u: Scenario) -> None:
    u.gh_overrides[
        f"api -H Accept: application/vnd.github.raw repos/{REPO}/contents/{UV_LOCK}?ref={HEAD}"
    ] = ok(uv_lock(u.uv_head, version=2))
    result = u.run()
    assert result.returncode == 2
    assert "version 2" in result.stderr


def test_an_audit_schema_uv_changed_exits_2(u: Scenario) -> None:
    u.uv_head_audit = {**uv_audit(), "schema": {"version": "2"}}
    result = u.run()
    assert result.returncode == 2
    assert "uv audit" in result.stderr


def test_a_failing_uv_audit_exits_2(u: Scenario) -> None:
    u.uv_overrides[f"head: {UV_AUDIT}"] = {"stderr": "error: invalid peer certificate\n", "code": 2}
    result = u.run()
    assert result.returncode == 2
    assert "invalid peer certificate" in result.stderr


def test_a_failing_pypi_request_exits_2(u: Scenario) -> None:
    u.curl_overrides[f"{CURL} {PYPI}/pypi/lib/1.0.1/json"] = {
        "stderr": "curl: (6) Could not resolve host\n",
        "code": 6,
    }
    result = u.run()
    assert result.returncode == 2
    assert "Could not resolve host" in result.stderr
