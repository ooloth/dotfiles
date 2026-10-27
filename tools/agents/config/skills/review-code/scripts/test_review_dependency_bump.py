"""Black-box tests for review_dependency_bump.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `gh` and a fake
`npm` on PATH answer from a table of canned responses and record every call, so no test reaches
GitHub or the npm registry.

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


class Scenario:
    """One PR that bumps pkg 1.0.0 to 1.0.1 cleanly. Each test changes the part it is about."""

    def __init__(self, tmp_path: Path) -> None:
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
        }
        return {**table, **self.gh_overrides}

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
        bin_dir = self.tmp_path / "bin"
        bin_dir.mkdir(exist_ok=True)
        for tool in ("gh", "npm"):
            path = bin_dir / tool
            path.write_text(FAKE_TOOL)
            path.chmod(0o755)
        (self.tmp_path / "gh.json").write_text(json.dumps(self.gh_table()))
        (self.tmp_path / "npm.json").write_text(json.dumps(self.npm_table()))
        env = {
            **os.environ,
            "PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            "FAKE_CALLS": str(self.calls_file),
            "FAKE_GH": str(self.tmp_path / "gh.json"),
            "FAKE_NPM": str(self.tmp_path / "npm.json"),
        }
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


@pytest.fixture
def s(tmp_path: Path) -> Scenario:
    return Scenario(tmp_path)


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


def test_a_pr_without_an_npm_lockfile_exits_2(s: Scenario) -> None:
    s.files = ["backend/uv.lock"]
    result = s.run()
    assert result.returncode == 2
    assert "package-lock.json" in result.stderr
    assert result.stdout == ""


def test_identical_lockfiles_exit_2(s: Scenario) -> None:
    s.head_lock = s.base_lock or {}
    result = s.run()
    assert result.returncode == 2
    assert "nothing to check" in result.stderr


def test_a_lockfile_beside_the_npm_one_is_flagged_as_unchecked(s: Scenario) -> None:
    s.files = [LOCK, "backend/uv.lock"]
    result = s.run()
    assert_flagged(result, "unchecked")
    assert "backend/uv.lock" in result.stdout


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
