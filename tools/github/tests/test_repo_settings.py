#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest", "hypothesis", "pydantic>=2,<3"]
# ///
"""Tests for tools/github/repo_settings.py.

Run with: uv run tools/github/tests/test_repo_settings.py

The pure steps (baseline, drift, the write requests and the pin check) are tested in-process, with
generated settings. What the script sends to GitHub is tested by running it as a subprocess with a
stub `gh` first on PATH, which answers from a JSON file and logs each call. The repo names are made
up, because this repo is public.
"""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from collections.abc import Iterator, Mapping
from pathlib import Path
from types import ModuleType
from typing import TYPE_CHECKING

import pytest
from hypothesis import given
from hypothesis import strategies as st

if TYPE_CHECKING:
    from tools.github.repo_settings import ActionRef, RepoSettings, Visibility, WriteRequest

SCRIPT = Path(__file__).resolve().parent.parent / "repo_settings.py"


def load() -> ModuleType:
    spec = importlib.util.spec_from_file_location("repo_settings", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["repo_settings"] = module
    spec.loader.exec_module(module)
    return module


rs = load()

# --- Generated settings ------------------------------------------------------------------------

action_refs = st.builds(
    rs.ActionRef,
    workflow=st.just(".github/workflows/ci.yml"),
    uses=st.sampled_from(["actions/checkout@v4", "owner/action@main"]),
)


@st.composite
def repo_settings(draw: st.DrawFn, visibility: Visibility | None = None) -> RepoSettings:
    chosen = visibility if visibility is not None else draw(st.sampled_from(list(rs.Visibility)))
    applicable = [
        s for s in rs.Setting if chosen is rs.Visibility.PUBLIC or s not in rs.PUBLIC_ONLY
    ]
    values = {s: draw(st.booleans()) for s in applicable}
    unpinned = tuple(draw(st.lists(action_refs, max_size=2)))
    return rs.RepoSettings(rs.RepoName("example/repo"), chosen, values, True, unpinned)


def simulate(settings: RepoSettings, requests: tuple[WriteRequest, ...]) -> RepoSettings:
    """The settings as they would be once GitHub has applied each request."""
    values = dict(settings.values)
    for request in requests:
        values[request.setting] = request.value
    return rs.RepoSettings(
        settings.repo, settings.visibility, values, settings.actions_enabled, settings.unpinned
    )


# --- Convergence and visibility (P2, P3, P4) ----------------------------------------------------


@given(repo_settings())
def test_the_requests_for_any_drift_leave_no_drift(settings: RepoSettings) -> None:
    wanted = rs.baseline(settings.visibility, settings.unpinned)
    after = simulate(settings, rs.requests_for(settings, wanted, rs.drift(settings, wanted)))
    assert rs.drift(after, wanted) == ()


@given(repo_settings())
def test_no_drift_means_no_requests(settings: RepoSettings) -> None:
    wanted = rs.baseline(settings.visibility, settings.unpinned)
    in_sync = simulate(settings, rs.requests_for(settings, wanted, rs.drift(settings, wanted)))
    assert rs.requests_for(in_sync, wanted, rs.drift(in_sync, wanted)) == ()


@given(repo_settings(visibility=rs.Visibility.PRIVATE))
def test_a_private_repo_is_never_asked_for_a_public_only_setting(settings: RepoSettings) -> None:
    wanted = rs.baseline(settings.visibility, settings.unpinned)
    assert not rs.PUBLIC_ONLY & set(wanted.wanted)
    requests = rs.requests_for(settings, wanted, rs.drift(settings, wanted))
    assert not {r.setting for r in requests} & rs.PUBLIC_ONLY


@given(st.sampled_from(list(rs.Visibility)), st.lists(action_refs, min_size=1, max_size=3))
def test_sha_pinning_is_never_wanted_while_an_action_is_unpinned(
    visibility: Visibility, unpinned: list[ActionRef]
) -> None:
    assert rs.Setting.SHA_PINNING not in rs.baseline(visibility, unpinned).wanted


def test_a_fully_pinned_repo_wants_sha_pinning() -> None:
    assert rs.baseline(rs.Visibility.PUBLIC, ()).wanted[rs.Setting.SHA_PINNING] is True


def test_alerts_are_written_before_security_updates() -> None:
    values = {s: False for s in rs.Setting}
    settings = rs.RepoSettings(rs.RepoName("example/repo"), rs.Visibility.PUBLIC, values, True, ())
    wanted = rs.baseline(rs.Visibility.PUBLIC, ())
    order = [r.setting for r in rs.requests_for(settings, wanted, rs.drift(settings, wanted))]
    assert order.index(rs.Setting.VULNERABILITY_ALERTS) < order.index(rs.Setting.SECURITY_FIXES)


# --- Which actions count as pinned (P4) ---------------------------------------------------------

SHA = "11d5960a326750d5838078e36cf38b85af677262"


@pytest.mark.parametrize(
    "uses",
    [
        f"actions/checkout@{SHA}",
        f"owner/repo/path/to/action@{SHA}",
        "./.github/actions/local",
        "docker://alpine@sha256:" + "a" * 64,
    ],
)
def test_pinned_references(uses: str) -> None:
    assert rs.is_pinned(uses)


@pytest.mark.parametrize(
    "uses",
    [
        "actions/checkout@v4",
        "owner/action@main",
        "dtolnay/rust-toolchain@stable",
        f"actions/checkout@{SHA[:12]}",
        "docker://alpine:3.20",
    ],
)
def test_unpinned_references(uses: str) -> None:
    assert not rs.is_pinned(uses)


def test_unpinned_actions_reads_every_uses_line_and_ignores_trailing_comments() -> None:
    workflow = f"""
jobs:
  check:
    steps:
      - uses: actions/checkout@{SHA} # v4.4.0
      - uses: "dtolnay/rust-toolchain@stable"
      - name: cache
        uses: Swatinem/rust-cache@v2
      - run: echo uses: not-an-action@v1
"""
    found = rs.unpinned_actions("ci.yml", workflow)
    assert [a.uses for a in found] == ["dtolnay/rust-toolchain@stable", "Swatinem/rust-cache@v2"]


# --- Running against a stub gh (P1, P3, P5) -----------------------------------------------------

STUB = """#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ["STUB_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")
responses = json.load(open(os.environ["STUB_RESPONSES"]))
if args[:2] == ["repo", "list"]:
    key = "repo list"
else:
    method = args[args.index("-X") + 1]
    key = method + " " + args[args.index("-X") + 2]
answer = responses.get(key, {"status": 404, "body": ""})
if 200 <= answer["status"] < 300:
    sys.stdout.write(answer["body"])
    sys.exit(0)
sys.stderr.write("gh: refused (HTTP %d)\\n" % answer["status"])
sys.exit(1)
"""


@pytest.fixture(scope="module")
def stubs(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    folder = tmp_path_factory.mktemp("stubs")
    gh = folder / "gh"
    gh.write_text(STUB)
    gh.chmod(0o755)
    folder.chmod(0o555)
    yield folder
    folder.chmod(0o755)


def ok(body: object) -> dict[str, object]:
    return {"status": 200, "body": body if isinstance(body, str) else json.dumps(body)}


def repo_answers(repo: str, visibility: str, *, alerts_on: bool) -> dict[str, object]:
    """GitHub's answers for one repo whose only drift is that alerts are off, when `alerts_on` is
    false."""
    public = visibility == "public"
    answers: dict[str, object] = {
        f"GET repos/{repo}": ok(
            {
                "visibility": visibility,
                "allow_auto_merge": True,
                "delete_branch_on_merge": True,
                "security_and_analysis": (
                    {
                        "secret_scanning": {"status": "enabled"},
                        "secret_scanning_push_protection": {"status": "enabled"},
                    }
                    if public
                    else None
                ),
            }
        ),
        f"GET repos/{repo}/automated-security-fixes": ok({"enabled": True, "paused": False}),
        f"GET repos/{repo}/actions/permissions": ok(
            {"enabled": True, "allowed_actions": "all", "sha_pinning_required": True}
        ),
        f"GET repos/{repo}/actions/permissions/workflow": ok(
            {"default_workflow_permissions": "read", "can_approve_pull_request_reviews": False}
        ),
    }
    if alerts_on:
        answers[f"GET repos/{repo}/vulnerability-alerts"] = {"status": 204, "body": ""}
    if public:
        answers[f"GET repos/{repo}/private-vulnerability-reporting"] = ok({"enabled": True})
    return answers


def run(
    stubs: Path, tmp_path: Path, mode: str, responses: Mapping[str, object]
) -> tuple[int, str, list[list[str]]]:
    answers = tmp_path / "responses.json"
    answers.write_text(json.dumps(responses))
    log = tmp_path / "calls.log"
    log.touch()
    env = {
        **os.environ,
        "PATH": f"{stubs}{os.pathsep}{os.environ['PATH']}",
        "STUB_RESPONSES": str(answers),
        "STUB_LOG": str(log),
    }
    done = subprocess.run(
        [sys.executable, str(SCRIPT), mode], env=env, capture_output=True, text=True, check=False
    )
    calls = [json.loads(line) for line in log.read_text().splitlines()]
    return done.returncode, done.stdout + done.stderr, calls


def listing(*repos: str) -> dict[str, object]:
    return {"repo list": ok([{"nameWithOwner": r} for r in repos])}


def test_check_sends_only_reads_and_exits_1_on_drift(stubs: Path, tmp_path: Path) -> None:
    responses = {
        **listing("example/public", "example/private"),
        **repo_answers("example/public", "public", alerts_on=False),
        **repo_answers("example/private", "private", alerts_on=True),
    }
    status, output, calls = run(stubs, tmp_path, "--check", responses)
    api_methods = {call[call.index("-X") + 1] for call in calls if call[0] == "api"}
    assert api_methods == {"GET"}
    assert status == 1
    assert "example/public: 1 setting(s) differ" in output
    assert "Dependabot alerts: off, wanted on" in output
    assert "✅ example/private: matches the baseline" in output


def test_check_never_reads_public_only_settings_of_a_private_repo(
    stubs: Path, tmp_path: Path
) -> None:
    responses = {
        **listing("example/private"),
        **repo_answers("example/private", "private", alerts_on=True),
    }
    status, output, calls = run(stubs, tmp_path, "--check", responses)
    assert status == 0, output
    assert not any("private-vulnerability-reporting" in " ".join(call) for call in calls)


def test_a_refused_write_names_the_repo_and_setting_and_the_rest_are_reported(
    stubs: Path, tmp_path: Path
) -> None:
    responses = {
        **listing("example/refuses", "example/fine"),
        **repo_answers("example/refuses", "public", alerts_on=False),
        "PUT repos/example/refuses/vulnerability-alerts": {"status": 403, "body": ""},
        **repo_answers("example/fine", "public", alerts_on=True),
    }
    status, output, _ = run(stubs, tmp_path, "--apply", responses)
    assert status == 1
    assert "example/refuses: GitHub refused to turn Dependabot alerts on" in output
    assert "PUT repos/example/refuses/vulnerability-alerts" in output
    assert "✅ example/fine: matches the baseline" in output


def test_an_unreadable_repo_is_reported_and_the_others_still_run(
    stubs: Path, tmp_path: Path
) -> None:
    responses = {
        **listing("example/gone", "example/fine"),
        **repo_answers("example/fine", "public", alerts_on=True),
    }
    status, output, _ = run(stubs, tmp_path, "--check", responses)
    assert status == 1
    assert "❌ example/gone: could not read its settings" in output
    assert "✅ example/fine: matches the baseline" in output


def test_no_tagged_repos_says_how_to_add_one(stubs: Path, tmp_path: Path) -> None:
    status, output, _ = run(stubs, tmp_path, "--check", listing())
    assert status == 1
    assert "gh repo edit ooloth/<name> --add-topic security-baseline" in output


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
