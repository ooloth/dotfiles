"""Black-box tests for security_feeds.py.

The script runs as a subprocess, never imported, so it stays a single file. Fake `gh` and `npm`
executables on PATH answer from a JSON file of canned responses and record every call, so no test
reaches GitHub or the npm registry.

The canned responses are the ones GitHub and npm returned on 2026-10-23: for example, a repo with
Dependabot alerts turned off answers 403 "Dependabot alerts are disabled for this repository."

Run:
  uv run --with pytest pytest tools/agents/config/skills/scan-system/scripts/test_security_feeds.py
"""

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).with_name("security_feeds.py")
REPO = "octo/widgets"

# Answers from a JSON file of {"<substring of the joined arguments>": {"exit", "stdout", "stderr"}}.
# The first matching key wins; no match fails like a request GitHub rejected.
FAKE_TOOL = """#!/usr/bin/env python3
import json, os, sys
args = os.path.basename(sys.argv[0]) + " " + " ".join(sys.argv[1:])
with open(os.environ["FAKE_CALLS"], "a") as calls:
    calls.write(args + "\\n")
with open(os.environ["FAKE_RESPONSES"]) as f:
    responses = json.load(f)
for key, response in responses.items():
    if key in args:
        sys.stdout.write(response.get("stdout", ""))
        sys.stderr.write(response.get("stderr", ""))
        sys.exit(response.get("exit", 0))
sys.stderr.write("fake: no canned response for: " + args + "\\n")
sys.exit(1)
"""

DEPENDABOT_ALERT = {
    "number": 1,
    "state": "open",
    "dependency": {"package": {"ecosystem": "npm", "name": "next"}, "scope": "runtime"},
    "security_advisory": {"severity": "critical", "summary": "RCE"},
}
CODE_SCANNING_ALERT = {
    "number": 1,
    "state": "open",
    "rule": {"id": "js/x", "security_severity_level": "high"},
}
SECRET_ALERT = {"number": 1, "state": "open", "secret_type": "github_personal_access_token"}

TURNED_OFF = {
    "dependabot/alerts": "Dependabot alerts are disabled for this repository.",
    "code-scanning/alerts": "Code scanning is not enabled for this repository. Please enable code "
    "scanning in the repository settings.",
    "secret-scanning/alerts": "Secret scanning is disabled on this repository.",
}
TURNED_OFF_STATUS = {
    "dependabot/alerts": 403,
    "code-scanning/alerts": 403,
    "secret-scanning/alerts": 404,
}


def ok(pages: list[list[dict[str, Any]]]) -> dict[str, Any]:
    return {"exit": 0, "stdout": json.dumps(pages)}


def gh_error(status: int, message: str) -> dict[str, Any]:
    # gh leaves a half-written body on stdout when a request fails, so stdout must not be trusted
    body = json.dumps({"message": message, "status": str(status)})
    return {"exit": 1, "stdout": f"[{body}", "stderr": f"gh: {message} (HTTP {status})\n"}


def npm_audit(packages: list[str]) -> dict[str, Any]:
    report = {
        "auditReportVersion": 2,
        "vulnerabilities": {name: {"name": name, "severity": "high"} for name in packages},
        "metadata": {"vulnerabilities": {"total": len(packages)}},
    }
    # npm audit exits 1 whenever it finds anything, so its exit status is not a failure signal
    return {"exit": 1 if packages else 0, "stdout": json.dumps(report)}


def all_clear() -> dict[str, dict[str, Any]]:
    return {feed: ok([[]]) for feed in TURNED_OFF}


class Harness:
    def __init__(self, tmp_path: Path) -> None:
        self.bin = tmp_path / "bin"
        self.bin.mkdir()
        self.project = tmp_path / "project"
        self.project.mkdir()
        self.calls = tmp_path / "calls.log"
        self.calls.touch()
        self.responses = tmp_path / "responses.json"
        self.path = f"{self.bin}{os.pathsep}{os.environ['PATH']}"

    def install(self, *tools: str) -> None:
        for tool in tools:
            path = self.bin / tool
            path.write_text(FAKE_TOOL)
            path.chmod(0o755)

    def only_these_on_path(self) -> None:
        """Put only the fakes, uv and the system directories on PATH, so a real gh can't be found."""
        uv = shutil.which("uv")
        assert uv is not None, "the tests run the script with uv"
        (self.bin / "uv").symlink_to(uv)
        self.path = f"{self.bin}{os.pathsep}/usr/bin{os.pathsep}/bin"

    def lockfile(self, name: str = "package-lock.json") -> None:
        (self.project / name).write_text("{}")

    def run(self, responses: dict[str, dict[str, Any]]) -> subprocess.CompletedProcess[str]:
        self.responses.write_text(json.dumps(responses))
        env = {
            **os.environ,
            "PATH": self.path,
            "FAKE_CALLS": str(self.calls),
            "FAKE_RESPONSES": str(self.responses),
        }
        return subprocess.run(
            ["uv", "run", "--script", str(SCRIPT), REPO, "--path", str(self.project)],
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )

    def call_lines(self) -> list[str]:
        return self.calls.read_text().splitlines()


@pytest.fixture
def harness(tmp_path: Path) -> Harness:
    h = Harness(tmp_path)
    h.install("gh", "npm")
    return h


def line_for(output: str, label: str) -> str:
    matches = [line for line in output.splitlines() if line.startswith(label)]
    assert len(matches) == 1, f"expected one line starting {label!r} in:\n{output}"
    return matches[0]


class TestFeeds:
    def test_an_empty_feed_is_counted_as_zero(self, harness: Harness) -> None:
        result = harness.run(all_clear())

        assert "counted 0 open" in line_for(result.stdout, "dependabot")
        assert result.returncode == 0

    def test_alerts_across_pages_are_all_counted(self, harness: Harness) -> None:
        responses = all_clear()
        responses["dependabot/alerts"] = ok([[DEPENDABOT_ALERT] * 100, [DEPENDABOT_ALERT] * 3])

        result = harness.run(responses)

        assert "counted 103 open" in line_for(result.stdout, "dependabot")

    @pytest.mark.parametrize("feed", sorted(TURNED_OFF))
    def test_a_feed_github_has_turned_off_is_reported_with_its_message(
        self, harness: Harness, feed: str
    ) -> None:
        responses = all_clear()
        responses[feed] = gh_error(TURNED_OFF_STATUS[feed], TURNED_OFF[feed])

        result = harness.run(responses)

        line = line_for(result.stdout, feed.split("/")[0])
        assert "turned off" in line
        assert TURNED_OFF[feed] in line
        assert result.returncode == 0

    # Each run reads all three feeds, so each feed gets its own status, covering 400-599 in 67 runs
    @pytest.mark.parametrize("first", range(400, 600, 3))
    def test_no_error_status_is_ever_counted(self, harness: Harness, first: int) -> None:
        statuses = dict(zip(sorted(TURNED_OFF), range(first, first + 3), strict=False))
        responses = {
            feed: gh_error(min(status, 599), "Something went wrong")
            for feed, status in statuses.items()
        }

        result = harness.run(responses)

        for feed, status in statuses.items():
            line = line_for(result.stdout, feed.split("/")[0])
            assert "counted" not in line
            assert "failed" in line
            assert f"HTTP {min(status, 599)}" in line
        assert result.returncode == 1

    def test_a_body_that_is_not_alerts_fails_instead_of_counting(self, harness: Harness) -> None:
        responses = all_clear()
        responses["dependabot/alerts"] = {"exit": 0, "stdout": json.dumps({"unexpected": True})}

        result = harness.run(responses)

        line = line_for(result.stdout, "dependabot")
        assert "failed" in line
        assert result.returncode == 1

    def test_a_failure_names_the_command_so_it_can_be_rerun(self, harness: Harness) -> None:
        responses = all_clear()
        responses["secret-scanning/alerts"] = gh_error(500, "Server Error")

        result = harness.run(responses)

        assert f"gh api repos/{REPO}/secret-scanning/alerts" in line_for(
            result.stdout, "secret-scanning"
        )

    def test_gh_not_installed_fails_every_feed(self, tmp_path: Path) -> None:
        h = Harness(tmp_path)
        h.install("npm")
        h.only_these_on_path()

        result = h.run({})

        for feed in ("dependabot", "code-scanning", "secret-scanning"):
            line = line_for(result.stdout, feed)
            assert "failed" in line and "gh is not installed" in line
        assert result.returncode == 1

    @pytest.mark.parametrize("repo", ["widgets", "octo/widgets --path x", "../etc/passwd", "octo/"])
    def test_a_repo_that_is_not_owner_slash_name_is_rejected_before_any_request(
        self, harness: Harness, repo: str
    ) -> None:
        harness.responses.write_text("{}")
        result = subprocess.run(
            ["uv", "run", "--script", str(SCRIPT), repo],
            capture_output=True,
            text=True,
            env={**os.environ, "PATH": harness.path, "FAKE_CALLS": str(harness.calls)},
            check=False,
        )

        assert result.returncode == 2
        assert "OWNER/NAME" in result.stderr
        assert harness.call_lines() == []

    def test_only_documented_filters_are_sent_and_only_with_get(self, harness: Harness) -> None:
        harness.run(all_clear())

        gh_calls = [line for line in harness.call_lines() if line.startswith("gh ")]
        assert len(gh_calls) == 3
        for call in gh_calls:
            assert "?state=open&per_page=100 " in call + " "
            assert "--method" not in call and " -X " not in call and " -f " not in call


class TestCrossCheck:
    def test_github_reporting_none_while_npm_audit_finds_some_is_a_disagreement(
        self, harness: Harness
    ) -> None:
        harness.lockfile()
        responses = {**all_clear(), "npm audit": npm_audit(["next", "vitest"])}

        result = harness.run(responses)

        line = line_for(result.stdout, "npm cross-check")
        assert "DISAGREE" in line
        assert "GitHub 0" in line and "npm audit 2" in line
        assert result.returncode == 0

    def test_github_reporting_some_while_npm_audit_finds_none_is_a_disagreement(
        self, harness: Harness
    ) -> None:
        harness.lockfile()
        responses = {**all_clear(), "npm audit": npm_audit([])}
        responses["dependabot/alerts"] = ok([[DEPENDABOT_ALERT]])

        result = harness.run(responses)

        assert "DISAGREE" in line_for(result.stdout, "npm cross-check")

    def test_dependabot_turned_off_while_npm_audit_finds_some_is_a_disagreement(
        self, harness: Harness
    ) -> None:
        harness.lockfile()
        responses = {**all_clear(), "npm audit": npm_audit(["next"])}
        responses["dependabot/alerts"] = gh_error(403, TURNED_OFF["dependabot/alerts"])

        result = harness.run(responses)

        assert "DISAGREE" in line_for(result.stdout, "npm cross-check")

    @pytest.mark.parametrize(
        ("github_alerts", "local_packages"),
        [(0, []), (3, ["next"])],
        ids=["both none", "both some, counted differently"],
    )
    def test_sources_that_agree_on_none_versus_some_agree(
        self, harness: Harness, github_alerts: int, local_packages: list[str]
    ) -> None:
        harness.lockfile()
        responses = {**all_clear(), "npm audit": npm_audit(local_packages)}
        responses["dependabot/alerts"] = ok([[DEPENDABOT_ALERT] * github_alerts])

        result = harness.run(responses)

        assert "agree" in line_for(result.stdout, "npm cross-check")
        assert "DISAGREE" not in result.stdout

    def test_only_alerts_for_the_scanned_ecosystem_are_compared(self, harness: Harness) -> None:
        harness.lockfile()
        cargo_alert = {
            **DEPENDABOT_ALERT,
            "dependency": {"package": {"ecosystem": "rust", "name": "rustls"}},
        }
        responses = {**all_clear(), "npm audit": npm_audit(["next"])}
        responses["dependabot/alerts"] = ok([[cargo_alert]])

        result = harness.run(responses)

        line = line_for(result.stdout, "npm cross-check")
        assert "DISAGREE" in line and "GitHub 0" in line

    def test_npm_not_installed_means_no_cross_check_with_the_reason(self, tmp_path: Path) -> None:
        h = Harness(tmp_path)
        h.install("gh")
        h.only_these_on_path()
        h.lockfile()

        result = h.run(all_clear())

        line = line_for(result.stdout, "npm cross-check")
        assert "cannot compare" in line
        assert "npm is not installed" in line

    def test_no_lockfile_says_there_is_no_local_cross_check(self, harness: Harness) -> None:
        result = harness.run(all_clear())

        line = line_for(result.stdout, "cross-check")
        assert "no lockfile" in line
        assert "package-lock.json" in line

    def test_npm_audit_output_that_is_not_a_report_fails(self, harness: Harness) -> None:
        harness.lockfile()
        responses = {**all_clear(), "npm audit": {"exit": 1, "stdout": "npm error code ENOLOCK"}}

        result = harness.run(responses)

        assert "failed" in line_for(result.stdout, "npm audit")
        assert result.returncode == 1

    def test_the_output_names_where_the_lockfile_was_sent(self, harness: Harness) -> None:
        harness.lockfile()
        responses = {**all_clear(), "npm audit": npm_audit([])}

        result = harness.run(responses)

        line = line_for(result.stdout, "npm audit")
        assert "npm registry" in line
        assert "package-lock.json" in line
        assert "npm audit --json --package-lock-only" in line
