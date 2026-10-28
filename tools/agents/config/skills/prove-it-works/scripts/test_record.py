"""Tests for record.py, the recorder prove-it-works runs every observation through.

The script stays a single file, so it is loaded from its path rather than imported as a package.
Property tests call its functions in-process. Command-line tests run it as a subprocess with
PROVE_IT_WORKS_HOME pointing at a temporary folder, so no test writes to the real evidence folder.

Run:
  uv run --with pytest --with hypothesis --with pydantic pytest \
    tools/agents/config/skills/prove-it-works/scripts/test_record.py
"""

import importlib.util
import json
import os
import subprocess
import sys
import time
from collections.abc import Iterator
from datetime import UTC, datetime
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest
from hypothesis import assume, given, settings
from hypothesis import strategies as st

SCRIPT = Path(__file__).with_name("record.py")
GOLDEN = Path(__file__).with_name("testdata") / "expected-report.txt"
REPO = "octo/widgets"
COMMIT = "abc1234def5678"


def _load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location("record", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    # dataclasses resolve their annotations through sys.modules, so register before running
    sys.modules["record"] = module
    spec.loader.exec_module(module)
    return module


rec = _load_script()


@pytest.fixture
def home(tmp_path: Path) -> Path:
    return tmp_path / "evidence"


def cli(home: Path, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    full_env = {**os.environ, "PROVE_IT_WORKS_HOME": str(home), **(env or {})}
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env=full_env,
        timeout=60,
    )


def start(home: Path) -> Path:
    result = cli(home, "start", "--repo", REPO, "--commit", COMMIT)
    assert result.returncode == 0, result.stderr
    return Path(result.stdout.strip())


def observation(run: Path, observation_id: str) -> dict:
    return json.loads((run / "observations" / f"{observation_id}.json").read_text())


def write_draft(tmp_path: Path, draft: dict) -> Path:
    path = tmp_path / "draft.json"
    path.write_text(json.dumps(draft))
    return path


# Credentials of each known shape. Each is built from parts so this file holds no literal token.
CREDENTIALS = {
    "jwt": st.builds(
        lambda h, p, s: f"eyJ{h}.eyJ{p}.{s}",
        st.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", min_size=8),
        st.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", min_size=8),
        st.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", min_size=8),
    ),
    "github-token": st.builds(
        lambda kind, body: f"gh{kind}_{body}",
        st.sampled_from("pousr"),
        st.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", min_size=36),
    ),
    "google-token": st.builds(
        lambda body: "ya29." + body,
        st.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", min_size=20),
    ),
    "google-api-key": st.builds(
        lambda body: "AIza" + body,
        st.text(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-",
            min_size=35,
            max_size=35,
        ),
    ),
    "atlassian-token": st.builds(
        lambda body: "ATATT3" + body,
        st.text("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_=-", min_size=20),
    ),
    "private-key": st.builds(
        lambda label, body: (
            f"-----BEGIN {label}PRIVATE KEY-----\n{body}\n-----END {label}PRIVATE KEY-----"
        ),
        st.sampled_from(["", "RSA ", "EC ", "OPENSSH "]),
        st.text("abcdefghijklmnopqrstuvwxyz0123456789+/=\n", min_size=1),
    ),
}
BEARER_VALUE = st.text(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-~+/", min_size=8
)
SURROUNDING = st.text("abcdefghijklmnopqrstuvwxyz :=\n{}\"'", max_size=40)


class TestRedaction:
    @given(
        kind=st.sampled_from(sorted(CREDENTIALS)),
        data=st.data(),
        before=SURROUNDING,
        after=SURROUNDING,
    )
    def test_a_credential_of_each_known_shape_is_removed_and_named(
        self, kind: str, data: st.DataObject, before: str, after: str
    ) -> None:
        secret = data.draw(CREDENTIALS[kind])
        output = f"{before} {secret} {after}".encode()

        redacted, kinds = rec.redact(output)

        assert secret.encode() not in redacted
        assert kind in kinds

    @given(value=BEARER_VALUE, before=SURROUNDING, after=SURROUNDING)
    def test_a_bearer_header_value_is_removed_and_named(
        self, value: str, before: str, after: str
    ) -> None:
        output = f"{before}\nAuthorization: Bearer {value}\n{after}".encode()

        redacted, kinds = rec.redact(output)

        assert f"Bearer {value}".encode() not in redacted
        assert "bearer" in kinds

    @given(output=st.binary(max_size=500))
    def test_output_with_no_credential_is_kept_byte_for_byte(self, output: bytes) -> None:
        assume(not rec.contains_credential(output))

        redacted, kinds = rec.redact(output)

        assert redacted == output
        assert kinds == ()


def make_run(tmp_path: Path) -> Any:
    return rec.open_run(tmp_path / "evidence", rec.RepoSlug(REPO), rec.CommitSha(COMMIT), NOW)


NOW = datetime(2026, 10, 28, 12, 0, tzinfo=UTC)


def record_text(run: Any, stdout: str, side: str = "after") -> Any:
    request = rec.ObservationRequest(
        command=rec.ShellCommand("printf something"),
        artifact=rec.ObservedArtifact("a host"),
        side=side,
        limit_seconds=10.0,
    )
    outcome = rec.RedactedOutcome(rec.Exited(0, stdout.encode(), b""), ())
    return rec.record(run, request, outcome, NOW, NOW)


LINES = st.lists(st.text("abcdefghijklmnopqrstuvwxyz 0123456789:", max_size=20), min_size=1)


class TestQuotes:
    @given(lines=LINES, data=st.data())
    @settings(max_examples=50)
    def test_a_quote_is_exactly_the_cited_lines_of_the_stored_output(
        self, tmp_path_factory: pytest.TempPathFactory, lines: list[str], data: st.DataObject
    ) -> None:
        run = make_run(tmp_path_factory.mktemp("run"))
        stored = record_text(run, "".join(f"{line}\n" for line in lines))
        first = data.draw(st.integers(min_value=1, max_value=len(lines)))
        last = data.draw(st.integers(min_value=first, max_value=len(lines)))
        draft = rec.parse_draft(
            json.dumps(
                {
                    "claim": "c",
                    "findings": [
                        {
                            "statement": "s",
                            "verdict": "proven",
                            "why": "w",
                            "cites": [{"observation": stored.id, "lines": [first, last]}],
                        }
                    ],
                }
            ),
            Path("draft.json"),
        )

        report = rec.resolve(draft, rec.load_observations(run))

        assert isinstance(report, rec.Report)
        (quote,) = report.findings[0].evidence
        assert quote.lines == tuple(lines[first - 1 : last])
        assert quote.line_count == len(lines)

    @given(count=st.integers(min_value=1, max_value=6), data=st.data())
    @settings(max_examples=30)
    def test_every_observation_is_cited_or_listed_as_uncited_exactly_once(
        self, tmp_path_factory: pytest.TempPathFactory, count: int, data: st.DataObject
    ) -> None:
        run = make_run(tmp_path_factory.mktemp("run"))
        ids = [record_text(run, "x\n").id for _ in range(count)]
        cited = data.draw(st.lists(st.sampled_from(ids), min_size=1, unique=True))
        draft = rec.parse_draft(
            json.dumps(
                {
                    "claim": "c",
                    "findings": [
                        {
                            "statement": f"s{n}",
                            "verdict": "proven",
                            "why": "w",
                            "cites": [{"observation": observation_id}],
                        }
                        for n, observation_id in enumerate(cited)
                    ],
                }
            ),
            Path("draft.json"),
        )

        report = rec.resolve(draft, rec.load_observations(run))

        assert isinstance(report, rec.Report)
        uncited = [o.id for o in report.uncited]
        assert sorted(uncited + cited) == sorted(ids)
        assert set(uncited).isdisjoint(cited)


class TestStart:
    def test_prints_a_new_folder_under_the_repo_and_commit(self, home: Path) -> None:
        run = start(home)

        assert run.parent == home / "octo-widgets" / COMMIT
        assert json.loads((run / "run.json").read_text())["repo"] == REPO

    def test_runs_started_at_once_for_the_same_commit_get_separate_folders(
        self, home: Path
    ) -> None:
        env = {**os.environ, "PROVE_IT_WORKS_HOME": str(home)}
        args = [sys.executable, str(SCRIPT), "start", "--repo", REPO, "--commit", COMMIT]
        procs = [
            subprocess.Popen(args, stdout=subprocess.PIPE, text=True, env=env) for _ in range(8)
        ]
        folders = [p.communicate(timeout=60)[0].strip() for p in procs]

        assert all(p.returncode == 0 for p in procs)
        assert len(set(folders)) == 8

    def test_refuses_a_repo_that_is_not_owner_slash_name(self, home: Path) -> None:
        result = cli(home, "start", "--repo", "widgets", "--commit", COMMIT)

        assert result.returncode == 2
        assert "OWNER/NAME" in result.stderr


class TestRun:
    def test_records_a_non_zero_exit_with_both_streams(self, home: Path) -> None:
        run = start(home)

        result = cli(
            home, "run", str(run), "--artifact", "a host", "--", "echo out; echo err >&2; exit 3"
        )

        assert result.returncode == 0, result.stderr
        recorded = observation(run, "o1")
        assert recorded["outcome"] == {"type": "exited", "code": 3}
        assert recorded["command"] == "echo out; echo err >&2; exit 3"
        assert recorded["artifact"] == "a host"
        assert (run / "observations" / "o1.stdout").read_bytes() == b"out\n"
        assert (run / "observations" / "o1.stderr").read_bytes() == b"err\n"
        assert "exited 3" in result.stdout

    def test_records_a_command_that_outlives_its_limit_as_timed_out_with_its_output(
        self, home: Path
    ) -> None:
        run = start(home)
        began = time.monotonic()

        result = cli(
            home,
            "run",
            str(run),
            "--artifact",
            "a host",
            "--timeout",
            "1",
            "--",
            "echo before; sleep 30",
        )

        assert time.monotonic() - began < 15
        assert result.returncode == 0, result.stderr
        assert observation(run, "o1")["outcome"] == {"type": "timed_out", "after": 1.0}
        assert (run / "observations" / "o1.stdout").read_bytes() == b"before\n"

    def test_records_a_command_that_cannot_start_apart_from_a_failed_one(
        self, home: Path, tmp_path: Path
    ) -> None:
        run = start(home)
        empty = tmp_path / "empty-path"
        empty.mkdir()

        result = cli(
            home, "run", str(run), "--artifact", "a host", "--", "true", env={"PATH": str(empty)}
        )

        assert result.returncode == 0, result.stderr
        assert observation(run, "o1")["outcome"]["type"] == "could_not_start"

    def test_stores_output_with_credentials_removed_and_notes_the_redaction(
        self, home: Path
    ) -> None:
        run = start(home)
        token = "ghp_" + "a1" * 20

        result = cli(home, "run", str(run), "--artifact", "a host", "--", f"echo {token}")

        assert token not in result.stdout
        assert token.encode() not in (run / "observations" / "o1.stdout").read_bytes()
        assert observation(run, "o1")["redactions"] == ["github-token"]

    def test_runs_recorded_at_once_get_separate_ids(self, home: Path) -> None:
        run = start(home)
        env = {**os.environ, "PROVE_IT_WORKS_HOME": str(home)}
        args = [sys.executable, str(SCRIPT), "run", str(run), "--artifact", "a", "--", "true"]
        procs = [
            subprocess.Popen(args, stdout=subprocess.PIPE, text=True, env=env) for _ in range(8)
        ]
        for p in procs:
            p.communicate(timeout=60)

        ids = sorted(p.name for p in (run / "observations").glob("*.json"))
        assert ids == sorted(f"o{n}.json" for n in range(1, 9))

    def test_refuses_a_folder_that_is_not_a_run(self, home: Path, tmp_path: Path) -> None:
        result = cli(home, "run", str(tmp_path), "--artifact", "a", "--", "true")

        assert result.returncode == 2
        assert "start" in result.stderr

    def test_refuses_an_empty_artifact(self, home: Path) -> None:
        run = start(home)

        result = cli(home, "run", str(run), "--artifact", " ", "--", "true")

        assert result.returncode == 2
        assert "artifact" in result.stderr


class TestAttach:
    def test_stores_a_copy_whose_hash_matches_the_original(
        self, home: Path, tmp_path: Path
    ) -> None:
        run = start(home)
        shot = tmp_path / "shot.png"
        shot.write_bytes(b"png-bytes")

        result = cli(home, "attach", str(run), str(shot), "--artifact", "a page", "--side", "after")

        assert result.returncode == 0, result.stderr
        stored = observation(run, "o1")["file"]
        assert (run / stored["path"]).read_bytes() == b"png-bytes"
        assert stored["sha256"] == (
            "ea80334363eed145dfeee51ebae7dc3f1cd7d0c7879f8bfd2070c061d3c33f56"
        )

    def test_refuses_a_missing_file(self, home: Path, tmp_path: Path) -> None:
        run = start(home)

        result = cli(home, "attach", str(run), str(tmp_path / "nope.png"), "--artifact", "a")

        assert result.returncode == 2
        assert "nope.png" in result.stderr


@pytest.fixture
def one_observation(home: Path) -> Iterator[Path]:
    run = start(home)
    assert cli(home, "run", str(run), "--artifact", "a", "--", "printf 'a\\nb\\n'").returncode == 0
    yield run


class TestReportRefuses:
    def report(
        self, home: Path, run: Path, tmp_path: Path, draft: dict
    ) -> subprocess.CompletedProcess:
        return cli(home, "report", str(run), str(write_draft(tmp_path, draft)))

    def test_a_proven_verdict_with_no_citations(
        self, home: Path, one_observation: Path, tmp_path: Path
    ) -> None:
        draft = {
            "claim": "c",
            "findings": [
                {"statement": "the page loads", "verdict": "proven", "why": "w", "cites": []}
            ],
        }

        result = self.report(home, one_observation, tmp_path, draft)

        assert result.returncode == 2
        assert "the page loads" in result.stderr

    def test_a_disproven_verdict_with_no_citations(
        self, home: Path, one_observation: Path, tmp_path: Path
    ) -> None:
        draft = {
            "claim": "c",
            "findings": [{"statement": "the page loads", "verdict": "disproven", "why": "w"}],
        }

        result = self.report(home, one_observation, tmp_path, draft)

        assert result.returncode == 2
        assert "the page loads" in result.stderr

    def test_a_not_observable_verdict_that_does_not_say_what_would_make_it_observable(
        self, home: Path, one_observation: Path, tmp_path: Path
    ) -> None:
        draft = {
            "claim": "c",
            "findings": [{"statement": "alerts fire", "verdict": "not_observable", "why": "w"}],
        }

        result = self.report(home, one_observation, tmp_path, draft)

        assert result.returncode == 2
        assert "alerts fire" in result.stderr

    def test_a_citation_of_an_unknown_observation(
        self, home: Path, one_observation: Path, tmp_path: Path
    ) -> None:
        draft = {
            "claim": "c",
            "findings": [
                {
                    "statement": "s",
                    "verdict": "proven",
                    "why": "w",
                    "cites": [{"observation": "o9"}],
                }
            ],
        }

        result = self.report(home, one_observation, tmp_path, draft)

        assert result.returncode == 2
        assert "o9" in result.stderr

    def test_a_citation_of_lines_past_the_end(
        self, home: Path, one_observation: Path, tmp_path: Path
    ) -> None:
        draft = {
            "claim": "c",
            "findings": [
                {
                    "statement": "s",
                    "verdict": "proven",
                    "why": "w",
                    "cites": [{"observation": "o1", "lines": [2, 5]}],
                }
            ],
        }

        result = self.report(home, one_observation, tmp_path, draft)

        assert result.returncode == 2
        assert "o1" in result.stderr
        assert "2 to 5" in result.stderr
        assert "2 lines" in result.stderr

    def test_a_citation_of_lines_in_a_file(self, home: Path, tmp_path: Path) -> None:
        run = start(home)
        shot = tmp_path / "shot.png"
        shot.write_bytes(b"png-bytes")
        assert cli(home, "attach", str(run), str(shot), "--artifact", "a page").returncode == 0
        draft = {
            "claim": "c",
            "findings": [
                {
                    "statement": "s",
                    "verdict": "proven",
                    "why": "w",
                    "cites": [{"observation": "o1", "lines": [1, 1]}],
                }
            ],
        }

        result = self.report(home, run, tmp_path, draft)

        assert result.returncode == 2
        assert "o1 is a file" in result.stderr


def test_the_rendered_report_keeps_its_shape(tmp_path: Path) -> None:
    run = rec.open_run(tmp_path, rec.RepoSlug(REPO), rec.CommitSha(COMMIT), NOW)

    def at(minute: int) -> datetime:
        return datetime(2026, 10, 28, 12, minute, tzinfo=UTC)

    def command(artifact: str, side: str, outcome: Any, minute: int) -> None:
        request = rec.ObservationRequest(
            command=rec.ShellCommand("curl -s https://app.example/health"),
            artifact=rec.ObservedArtifact(artifact),
            side=side,
            limit_seconds=10.0,
        )
        rec.record(run, request, outcome, at(minute), at(minute))

    command(
        "app.example /health on revision app-00042",
        "before",
        rec.RedactedOutcome(rec.Exited(1, b"status: down\n", b""), ()),
        0,
    )
    command(
        "app.example /health on revision app-00043",
        "after",
        rec.RedactedOutcome(rec.Exited(0, b"status: ok\nversion: 43\nuptime: 5s\n", b""), ()),
        5,
    )
    shot = tmp_path / "screenshot.png"
    shot.write_bytes(b"png-bytes")
    rec.store(
        run,
        shot,
        rec.ObservedArtifact("https://app.example/settings on revision app-00043"),
        "after",
        at(6),
    )
    command(
        "app log on revision app-00043",
        "unpaired",
        rec.RedactedOutcome(rec.Exited(0, b"token=[REDACTED jwt]\n", b""), ("jwt",)),
        7,
    )
    draft = rec.parse_draft(
        json.dumps(
            {
                "claim": "The health endpoint reports ok after the deploy",
                "findings": [
                    {
                        "statement": "The health endpoint reports ok on the new revision",
                        "verdict": "proven",
                        "why": "Before the deploy it reported down; after, ok with version 43.",
                        "cites": [
                            {"observation": "o1", "lines": [1, 1]},
                            {"observation": "o2", "lines": [1, 2]},
                            {"observation": "o3"},
                        ],
                    },
                    {
                        "statement": "Alerts fire when the endpoint is down",
                        "verdict": "not_observable",
                        "why": "Triggering an outage in dev needs approval.",
                        "needs": "Approval to stop the dev API for one minute",
                    },
                ],
                "unobserved": ["Behaviour in prod, which this change does not reach"],
            }
        ),
        Path("draft.json"),
    )

    report = rec.resolve(draft, rec.load_observations(run))
    assert isinstance(report, rec.Report)

    rendered = rec.render(report, run).replace(str(run.dir), "<run>")
    assert rendered == GOLDEN.read_text()
