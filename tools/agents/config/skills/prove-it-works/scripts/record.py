#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic>=2"]
# ///
"""Record what prove-it-works observes, so its report quotes the evidence instead of retyping it.

Every observation goes into one evidence run: a new folder under
~/Repos/agents/prove-it-works/<owner>-<repo>/<commit>/ (PROVE_IT_WORKS_HOME moves the root). `run`
executes a shell command with a time limit and stores the command, the artifact it observed, which
side of the change it was (before or after), how it ended, and its raw stdout and stderr. `attach`
stores a copy of a file, such as a screenshot, with its hash. Credentials of known shapes are
removed before anything is written, and each removal is noted on the observation.

`report` reads a draft the model writes, which says for each claim whether it is proven, disproven
or not observable and which observations show it. A proven or disproven claim must cite evidence,
and a not-observable one must say what would make it observable. The report quotes the cited lines
from the stored files, and lists every observation no finding cites, so evidence against a claim
can't be left out.

Usage:
  record.py start --repo OWNER/NAME --commit SHA
  record.py run RUN_DIR --artifact TEXT [--side before|after] [--timeout SECONDS] -- COMMAND
  record.py attach RUN_DIR FILE --artifact TEXT [--side before|after]
  record.py report RUN_DIR DRAFT_JSON

`start` prints the run folder. `run` exits 0 once the observation is recorded, whatever the command
did, and prints how it ended. Every subcommand exits 2 with a sentence when it can't do its job.

Draft shape:
  {"claim": "...",
   "findings": [{"statement": "...", "verdict": "proven" | "disproven", "why": "...",
                 "cites": [{"observation": "o2", "stream": "stdout", "lines": [3, 5]}]},
                {"statement": "...", "verdict": "not_observable", "why": "...", "needs": "..."}],
   "unobserved": ["..."]}
  `stream` defaults to stdout. `lines` is 1-based and inclusive, and may be left out for an output
  of at most 200 lines. A file observation is cited with `observation` alone.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import secrets
import shutil
import signal
import subprocess
import sys
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Annotated, Literal, NewType, assert_never

from pydantic import BaseModel, ConfigDict, Field, TypeAdapter, ValidationError

RepoSlug = NewType("RepoSlug", str)
CommitSha = NewType("CommitSha", str)
ShellCommand = NewType("ShellCommand", str)
ObservedArtifact = NewType("ObservedArtifact", str)
ObservationId = NewType("ObservationId", str)
Side = Literal["before", "after", "unpaired"]
Stream = Literal["stdout", "stderr"]
CredentialKind = Literal[
    "private-key",
    "jwt",
    "github-token",
    "google-token",
    "google-api-key",
    "atlassian-token",
    "bearer",
]

DEFAULT_HOME = Path.home() / "Repos" / "agents" / "prove-it-works"
RUN_MARKER = "run.json"
OBSERVATIONS = "observations"
MAX_OBSERVATIONS = 10_000
MAX_RUN_ATTEMPTS = 100
MAX_UNRANGED_LINES = 200
DEFAULT_LIMIT_SECONDS = 300.0

# Checked in this order, so a JWT inside a bearer header is named as a JWT. The bearer pattern skips
# a value that is already a redaction marker.
CREDENTIAL_PATTERNS: tuple[tuple[CredentialKind, re.Pattern[bytes]], ...] = (
    (
        "private-key",
        re.compile(
            rb"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.DOTALL
        ),
    ),
    ("jwt", re.compile(rb"eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")),
    ("github-token", re.compile(rb"gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}")),
    ("google-token", re.compile(rb"ya29\.[A-Za-z0-9_-]{20,}")),
    ("google-api-key", re.compile(rb"AIza[A-Za-z0-9_-]{35}")),
    ("atlassian-token", re.compile(rb"ATATT3[A-Za-z0-9_=-]{20,}")),
    ("bearer", re.compile(rb"(?i)(?<=bearer )(?!\[REDACTED )[^\s\"']+")),
)


# Domain types


@dataclass(frozen=True)
class EvidenceRun:
    dir: Path

    @property
    def observations(self) -> Path:
        return self.dir / OBSERVATIONS


@dataclass(frozen=True)
class ObservationRequest:
    command: ShellCommand
    artifact: ObservedArtifact
    side: Side
    limit_seconds: float


@dataclass(frozen=True)
class Exited:
    code: int
    stdout: bytes
    stderr: bytes


@dataclass(frozen=True)
class TimedOut:
    after: float
    stdout: bytes
    stderr: bytes


@dataclass(frozen=True)
class CouldNotStart:
    reason: str


CommandOutcome = Exited | TimedOut | CouldNotStart


@dataclass(frozen=True)
class RedactedOutcome:
    outcome: CommandOutcome
    redactions: tuple[CredentialKind, ...]


@dataclass(frozen=True)
class StoredFile:
    path: str
    sha256: str
    size: int


@dataclass(frozen=True)
class CommandObservation:
    id: ObservationId
    artifact: ObservedArtifact
    side: Side
    started_at: datetime
    finished_at: datetime
    command: ShellCommand
    outcome: StoredOutcome
    redactions: tuple[CredentialKind, ...]
    stdout: bytes
    stderr: bytes


@dataclass(frozen=True)
class FileObservation:
    id: ObservationId
    artifact: ObservedArtifact
    side: Side
    started_at: datetime
    file: StoredFile


Observation = CommandObservation | FileObservation


@dataclass(frozen=True)
class ExitedRecord:
    code: int


@dataclass(frozen=True)
class TimedOutRecord:
    after: float


@dataclass(frozen=True)
class CouldNotStartRecord:
    reason: str


StoredOutcome = ExitedRecord | TimedOutRecord | CouldNotStartRecord


# The draft the model writes


class _Draft(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)


class Citation(_Draft):
    observation: str
    stream: Stream = "stdout"
    lines: tuple[Annotated[int, Field(ge=1)], Annotated[int, Field(ge=1)]] | None = None


class ProvenDraft(_Draft):
    statement: str = Field(min_length=1)
    verdict: Literal["proven"]
    why: str
    cites: list[Citation] = Field(min_length=1)


class DisprovenDraft(_Draft):
    statement: str = Field(min_length=1)
    verdict: Literal["disproven"]
    why: str
    cites: list[Citation] = Field(min_length=1)


class NotObservableDraft(_Draft):
    statement: str = Field(min_length=1)
    verdict: Literal["not_observable"]
    why: str
    needs: str = Field(min_length=1)
    cites: list[Citation] = []


FindingDraft = Annotated[
    ProvenDraft | DisprovenDraft | NotObservableDraft, Field(discriminator="verdict")
]


class Draft(_Draft):
    claim: str = Field(min_length=1)
    findings: list[FindingDraft] = Field(min_length=1)
    unobserved: list[str] = []


@dataclass(frozen=True)
class DraftRejected:
    draft_path: Path
    field: str
    reason: str


# The resolved report


@dataclass(frozen=True)
class Quote:
    observation: CommandObservation
    stream: Stream
    first: int
    lines: tuple[str, ...]
    line_count: int


@dataclass(frozen=True)
class FileEvidence:
    observation: FileObservation


Evidence = Quote | FileEvidence


@dataclass(frozen=True)
class Proven:
    statement: str
    why: str
    evidence: tuple[Evidence, ...]


@dataclass(frozen=True)
class Disproven:
    statement: str
    why: str
    evidence: tuple[Evidence, ...]


@dataclass(frozen=True)
class NotObservable:
    statement: str
    why: str
    needs: str
    evidence: tuple[Evidence, ...]


Finding = Proven | Disproven | NotObservable


@dataclass(frozen=True)
class Report:
    claim: str
    findings: tuple[Finding, ...]
    uncited: tuple[Observation, ...]
    unobserved: tuple[str, ...]


@dataclass(frozen=True)
class UnknownObservation:
    id: str


@dataclass(frozen=True)
class LinesOutOfRange:
    id: str
    stream: Stream
    lines: tuple[int, int]
    line_count: int


@dataclass(frozen=True)
class LinesRequired:
    id: str
    stream: Stream
    line_count: int


@dataclass(frozen=True)
class NotACommand:
    id: str


ResolveFailure = UnknownObservation | LinesOutOfRange | LinesRequired | NotACommand


@dataclass(frozen=True)
class Refused:
    """An expected failure, reported to the caller as one sentence."""

    sentence: str


# Credentials


def contains_credential(data: bytes) -> bool:
    return any(pattern.search(data) for _, pattern in CREDENTIAL_PATTERNS)


def redact(data: bytes) -> tuple[bytes, tuple[CredentialKind, ...]]:
    kinds: list[CredentialKind] = []
    for kind, pattern in CREDENTIAL_PATTERNS:
        data, count = pattern.subn(f"[REDACTED {kind}]".encode(), data)
        if count:
            kinds.append(kind)
    for kind, pattern in CREDENTIAL_PATTERNS:
        assert not pattern.search(data), f"a {kind} survived redaction"
    return data, tuple(kinds)


def redact_outcome(outcome: CommandOutcome) -> RedactedOutcome:
    match outcome:
        case Exited(code, stdout, stderr):
            out, out_kinds = redact(stdout)
            err, err_kinds = redact(stderr)
            return RedactedOutcome(Exited(code, out, err), _merge(out_kinds, err_kinds))
        case TimedOut(after, stdout, stderr):
            out, out_kinds = redact(stdout)
            err, err_kinds = redact(stderr)
            return RedactedOutcome(TimedOut(after, out, err), _merge(out_kinds, err_kinds))
        case CouldNotStart():
            return RedactedOutcome(outcome, ())
        case _:
            assert_never(outcome)


def _merge(*groups: tuple[CredentialKind, ...]) -> tuple[CredentialKind, ...]:
    seen = {kind for group in groups for kind in group}
    return tuple(kind for kind, _ in CREDENTIAL_PATTERNS if kind in seen)


# Runs


def open_run(root: Path, repo: RepoSlug, commit: CommitSha, now: datetime) -> EvidenceRun:
    owner, name = repo.split("/", 1)
    parent = root / f"{owner}-{name}" / commit
    parent.mkdir(parents=True, exist_ok=True)
    stamp = now.astimezone(UTC).strftime("%Y%m%dT%H%M%SZ")
    for _ in range(MAX_RUN_ATTEMPTS):
        folder = parent / f"{stamp}-{secrets.token_hex(3)}"
        try:
            folder.mkdir()
        except FileExistsError:
            continue
        (folder / OBSERVATIONS).mkdir()
        marker = {"repo": repo, "commit": commit, "started_at": _iso(now)}
        (folder / RUN_MARKER).write_text(json.dumps(marker, indent=2) + "\n")
        return EvidenceRun(folder)
    raise AssertionError(f"no free run folder under {parent} after {MAX_RUN_ATTEMPTS} attempts")


def load_run(folder: Path) -> EvidenceRun | Refused:
    if not (folder / RUN_MARKER).is_file() or not (folder / OBSERVATIONS).is_dir():
        return Refused(f"{folder} is not an evidence run. Create one with `record.py start`.")
    return EvidenceRun(folder)


def _reserve_id(run: EvidenceRun) -> tuple[ObservationId, int]:
    """Claim the next free observation id by creating its file exclusively."""
    for n in range(1, MAX_OBSERVATIONS + 1):
        path = run.observations / f"o{n}.json"
        try:
            fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            continue
        return ObservationId(f"o{n}"), fd
    raise AssertionError(f"{run.dir} already holds {MAX_OBSERVATIONS} observations")


def execute(request: ObservationRequest) -> CommandOutcome:
    bash = shutil.which("bash")
    if bash is None:
        return CouldNotStart("bash is not on PATH")
    try:
        proc = subprocess.Popen(
            [bash, "-c", request.command],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
    except OSError as error:
        return CouldNotStart(str(error))
    try:
        stdout, stderr = proc.communicate(timeout=request.limit_seconds)
    except subprocess.TimeoutExpired:
        # The command runs in its own process group, so this also ends anything it started that
        # would otherwise keep the pipes open.
        os.killpg(proc.pid, signal.SIGKILL)
        stdout, stderr = proc.communicate()
        return TimedOut(request.limit_seconds, stdout, stderr)
    return Exited(proc.returncode, stdout, stderr)


def record(
    run: EvidenceRun,
    request: ObservationRequest,
    outcome: RedactedOutcome,
    started: datetime,
    finished: datetime,
) -> CommandObservation:
    observation_id, fd = _reserve_id(run)
    match outcome.outcome:
        case Exited(code, stdout, stderr):
            stored: StoredOutcome = ExitedRecord(code)
        case TimedOut(after, stdout, stderr):
            stored = TimedOutRecord(after)
        case CouldNotStart(reason):
            stored, stdout, stderr = CouldNotStartRecord(reason), b"", b""
        case _:
            assert_never(outcome.outcome)
    assert not contains_credential(stdout), "stdout reached record() unredacted"
    assert not contains_credential(stderr), "stderr reached record() unredacted"
    (run.observations / f"{observation_id}.stdout").write_bytes(stdout)
    (run.observations / f"{observation_id}.stderr").write_bytes(stderr)
    metadata = {
        "id": observation_id,
        "kind": "command",
        "artifact": request.artifact,
        "side": request.side,
        "started_at": _iso(started),
        "finished_at": _iso(finished),
        "command": request.command,
        "outcome": _outcome_json(stored),
        "redactions": list(outcome.redactions),
    }
    with os.fdopen(fd, "w") as handle:
        handle.write(json.dumps(metadata, indent=2) + "\n")
    return CommandObservation(
        id=observation_id,
        artifact=request.artifact,
        side=request.side,
        started_at=started,
        finished_at=finished,
        command=request.command,
        outcome=stored,
        redactions=outcome.redactions,
        stdout=stdout,
        stderr=stderr,
    )


def store(
    run: EvidenceRun, source: Path, artifact: ObservedArtifact, side: Side, now: datetime
) -> FileObservation | Refused:
    if not source.is_file():
        return Refused(f"{source} is not a file, so there is nothing to attach.")
    observation_id, fd = _reserve_id(run)
    relative = f"{OBSERVATIONS}/{observation_id}-{source.name}"
    shutil.copyfile(source, run.dir / relative)
    content = (run.dir / relative).read_bytes()
    stored = StoredFile(relative, hashlib.sha256(content).hexdigest(), len(content))
    metadata = {
        "id": observation_id,
        "kind": "file",
        "artifact": artifact,
        "side": side,
        "started_at": _iso(now),
        "file": {"path": stored.path, "sha256": stored.sha256, "size": stored.size},
        "source": str(source),
    }
    with os.fdopen(fd, "w") as handle:
        handle.write(json.dumps(metadata, indent=2) + "\n")
    return FileObservation(observation_id, artifact, side, now, stored)


def _outcome_json(outcome: StoredOutcome) -> dict[str, object]:
    match outcome:
        case ExitedRecord(code):
            return {"type": "exited", "code": code}
        case TimedOutRecord(after):
            return {"type": "timed_out", "after": after}
        case CouldNotStartRecord(reason):
            return {"type": "could_not_start", "reason": reason}
        case _:
            assert_never(outcome)


# Reading stored observations back. A person can edit these files, so they are parsed.


class _Stored(BaseModel):
    model_config = ConfigDict(extra="ignore", frozen=True)


class _ExitedJson(_Stored):
    type: Literal["exited"]
    code: int


class _TimedOutJson(_Stored):
    type: Literal["timed_out"]
    after: float


class _CouldNotStartJson(_Stored):
    type: Literal["could_not_start"]
    reason: str


class _FileJson(_Stored):
    path: str
    sha256: str
    size: int


class _CommandJson(_Stored):
    id: str
    kind: Literal["command"]
    artifact: str
    side: Side
    started_at: datetime
    finished_at: datetime
    command: str
    outcome: Annotated[
        _ExitedJson | _TimedOutJson | _CouldNotStartJson, Field(discriminator="type")
    ]
    redactions: list[CredentialKind]


class _FileObservationJson(_Stored):
    id: str
    kind: Literal["file"]
    artifact: str
    side: Side
    started_at: datetime
    file: _FileJson


_OBSERVATION_JSON = TypeAdapter(
    Annotated[_CommandJson | _FileObservationJson, Field(discriminator="kind")]
)


def load_observations(run: EvidenceRun) -> list[Observation]:
    found: list[Observation] = []
    for path in sorted(run.observations.glob("o*.json"), key=lambda p: int(p.stem[1:])):
        text = path.read_text()
        if not text:
            continue  # reserved by a `run` still in progress
        match _OBSERVATION_JSON.validate_json(text):
            case _CommandJson() as raw:
                outcome: StoredOutcome
                match raw.outcome:
                    case _ExitedJson(code=code):
                        outcome = ExitedRecord(code)
                    case _TimedOutJson(after=after):
                        outcome = TimedOutRecord(after)
                    case _CouldNotStartJson(reason=reason):
                        outcome = CouldNotStartRecord(reason)
                    case _:
                        assert_never(raw.outcome)
                found.append(
                    CommandObservation(
                        id=ObservationId(raw.id),
                        artifact=ObservedArtifact(raw.artifact),
                        side=raw.side,
                        started_at=raw.started_at,
                        finished_at=raw.finished_at,
                        command=ShellCommand(raw.command),
                        outcome=outcome,
                        redactions=tuple(raw.redactions),
                        stdout=(run.observations / f"{raw.id}.stdout").read_bytes(),
                        stderr=(run.observations / f"{raw.id}.stderr").read_bytes(),
                    )
                )
            case _FileObservationJson() as raw:
                stored = StoredFile(raw.file.path, raw.file.sha256, raw.file.size)
                found.append(
                    FileObservation(
                        ObservationId(raw.id),
                        ObservedArtifact(raw.artifact),
                        raw.side,
                        raw.started_at,
                        stored,
                    )
                )
    return found


# Drafts and reports


def parse_draft(text: str, path: Path) -> Draft | DraftRejected:
    try:
        draft = Draft.model_validate_json(text)
    except ValidationError as error:
        problem = error.errors()[0]
        location = problem["loc"]
        return DraftRejected(path, _describe_location(text, location), problem["msg"])
    for finding in draft.findings:
        for citation in finding.cites:
            if citation.lines is not None and citation.lines[0] > citation.lines[1]:
                return DraftRejected(
                    path,
                    f'"{finding.statement}"',
                    f"cites lines {citation.lines[0]} to {citation.lines[1]}, which run backwards",
                )
    return draft


def _describe_location(text: str, location: tuple[int | str, ...]) -> str:
    """Name a validation error's place in the draft by its finding's statement where it has one."""
    if len(location) >= 2 and location[0] == "findings" and isinstance(location[1], int):
        try:
            statement = json.loads(text)["findings"][location[1]]["statement"]
        except (KeyError, IndexError, TypeError, json.JSONDecodeError):
            statement = None
        rest = ".".join(str(part) for part in location[2:])
        if isinstance(statement, str):
            return f'the finding "{statement}"' + (f" ({rest})" if rest else "")
    return ".".join(str(part) for part in location) or "the draft"


def resolve(draft: Draft, observations: list[Observation]) -> Report | ResolveFailure:
    by_id = {observation.id: observation for observation in observations}
    cited: set[str] = set()
    findings: list[Finding] = []
    for finding in draft.findings:
        evidence: list[Evidence] = []
        for citation in finding.cites:
            resolved = _resolve_citation(citation, by_id)
            match resolved:
                case Quote() | FileEvidence():
                    evidence.append(resolved)
                    cited.add(citation.observation)
                case _:
                    return resolved
        match finding:
            case ProvenDraft():
                findings.append(Proven(finding.statement, finding.why, tuple(evidence)))
            case DisprovenDraft():
                findings.append(Disproven(finding.statement, finding.why, tuple(evidence)))
            case NotObservableDraft():
                findings.append(
                    NotObservable(finding.statement, finding.why, finding.needs, tuple(evidence))
                )
            case _:
                assert_never(finding)
    uncited = tuple(o for o in observations if o.id not in cited)
    assert len(cited) + len(uncited) == len(observations), "an observation was counted twice"
    return Report(draft.claim, tuple(findings), uncited, tuple(draft.unobserved))


def _resolve_citation(
    citation: Citation, by_id: dict[ObservationId, Observation]
) -> Evidence | ResolveFailure:
    observation = by_id.get(ObservationId(citation.observation))
    match observation:
        case None:
            return UnknownObservation(citation.observation)
        case FileObservation():
            if citation.lines is not None:
                return NotACommand(citation.observation)
            return FileEvidence(observation)
        case CommandObservation():
            pass
        case _:
            assert_never(observation)
    output = observation.stdout if citation.stream == "stdout" else observation.stderr
    all_lines = output.decode(errors="replace").splitlines()
    if citation.lines is None:
        if len(all_lines) > MAX_UNRANGED_LINES:
            return LinesRequired(citation.observation, citation.stream, len(all_lines))
        first, last = 1, len(all_lines)
    else:
        first, last = citation.lines
        if last > len(all_lines):
            return LinesOutOfRange(
                citation.observation, citation.stream, (first, last), len(all_lines)
            )
    quoted = tuple(all_lines[first - 1 : last])
    assert quoted == tuple(all_lines)[first - 1 : last], "a quote is not a slice of its output"
    return Quote(observation, citation.stream, first, quoted, len(all_lines))


def describe_failure(failure: ResolveFailure, run: EvidenceRun) -> str:
    match failure:
        case UnknownObservation(observation_id):
            return f"The draft cites {observation_id}, which {run.dir} does not hold."
        case LinesOutOfRange(observation_id, stream, (first, last), count):
            noun = "line" if count == 1 else "lines"
            return (
                f"The draft cites lines {first} to {last} of {observation_id}'s {stream}, "
                f"which has {count} {noun}."
            )
        case LinesRequired(observation_id, stream, count):
            return (
                f"The draft cites all of {observation_id}'s {stream}, which has {count} lines. "
                f"Name the lines that show the claim, at most {MAX_UNRANGED_LINES} at a time."
            )
        case NotACommand(observation_id):
            return f"{observation_id} is a file, so it has no lines to cite."
        case _:
            assert_never(failure)


def _verdict_label(finding: Finding) -> str:
    match finding:
        case Proven():
            return "✅ Proven"
        case Disproven():
            return "❌ Disproven"
        case NotObservable():
            return "❓ Not observable here"
        case _:
            assert_never(finding)


def render(report: Report, run: EvidenceRun) -> str:
    parts = [
        "# Proof",
        f"**Claim:** {report.claim}",
        f"**Evidence:** `{run.dir}`",
        "## Findings",
    ]
    shown = 0
    for number, finding in enumerate(report.findings, start=1):
        parts.append(f"### {number}. {_verdict_label(finding)}: {finding.statement}")
        if finding.why:
            parts.append(finding.why)
        for evidence in finding.evidence:
            parts.extend(_render_evidence(evidence))
        if isinstance(finding, NotObservable):
            parts.append(f"**What would make it observable:** {finding.needs}")
        shown += 1
    assert shown == len(report.findings), "a finding was not rendered"
    parts.append("## Uncited observations")
    if report.uncited:
        parts.append("\n".join(f"- {_uncited_line(o)}" for o in report.uncited))
    else:
        parts.append("None.")
    parts.append("## Not observed")
    parts.append("\n".join(f"- {item}" for item in report.unobserved) or "None.")
    return "\n\n".join(parts) + "\n"


def _header(observation: Observation) -> str:
    head = f"**{observation.id}** · {observation.side} · {observation.artifact}"
    match observation:
        case CommandObservation():
            fields = [head, _describe_outcome(observation.outcome)]
            if observation.redactions:
                fields.append("redacted: " + ", ".join(observation.redactions))
            fields.append(_iso(observation.started_at))
            return " · ".join(fields)
        case FileObservation(file=stored):
            return " · ".join(
                [
                    head,
                    f"file `{stored.path}`",
                    f"sha256 {stored.sha256}",
                    f"{stored.size} bytes",
                    _iso(observation.started_at),
                ]
            )
        case _:
            assert_never(observation)


def _describe_outcome(outcome: StoredOutcome) -> str:
    match outcome:
        case ExitedRecord(code):
            return f"exited {code}"
        case TimedOutRecord(after):
            return f"timed out after {after:g}s"
        case CouldNotStartRecord(reason):
            return f"could not start: {reason}"
        case _:
            assert_never(outcome)


def _render_evidence(evidence: Evidence) -> list[str]:
    match evidence:
        case FileEvidence(observation):
            return [_header(observation)]
        case Quote(observation, stream, first, lines, count):
            last = first + len(lines) - 1
            if count == 0:
                where = f"{stream} is empty, from `{OBSERVATIONS}/{observation.id}.{stream}`."
                return [_header(observation), _fence("console", f"$ {observation.command}"), where]
            span = f"line {first}" if first == last else f"lines {first} to {last}"
            where = f"{stream} {span} of {count}, from `{OBSERVATIONS}/{observation.id}.{stream}`:"
            return [
                _header(observation),
                _fence("console", f"$ {observation.command}"),
                where,
                _fence("text", "\n".join(lines)),
            ]
        case _:
            assert_never(evidence)


def _uncited_line(observation: Observation) -> str:
    match observation:
        case CommandObservation():
            return f"{_header(observation)} · `{OBSERVATIONS}/{observation.id}.stdout`"
        case FileObservation():
            return _header(observation)
        case _:
            assert_never(observation)


def _fence(language: str, body: str) -> str:
    longest = max((len(run) for run in re.findall(r"`+", body)), default=0)
    ticks = "`" * max(3, longest + 1)
    return f"{ticks}{language}\n{body}\n{ticks}"


def _iso(moment: datetime) -> str:
    return moment.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


# Command line


def _home() -> Path:
    return Path(os.environ.get("PROVE_IT_WORKS_HOME", DEFAULT_HOME))


def _artifact(text: str) -> ObservedArtifact | Refused:
    if not text.strip():
        return Refused("--artifact is empty. Name what was observed, such as a host or revision.")
    return ObservedArtifact(text.strip())


def _side(text: str | None) -> Side:
    match text:
        case "before" | "after":
            return text
        case None:
            return "unpaired"
        case _:
            raise AssertionError(f"argparse let through side {text!r}")


def _now() -> datetime:
    return datetime.now(UTC)


def cmd_start(args: argparse.Namespace) -> int | Refused:
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", args.repo):
        return Refused(f"--repo is {args.repo!r}. Give it as OWNER/NAME, such as octo/widgets.")
    if not re.fullmatch(r"[0-9a-fA-F]{7,40}", args.commit):
        return Refused(f"--commit is {args.commit!r}. Give the commit SHA, 7 to 40 hex digits.")
    run = open_run(_home(), RepoSlug(args.repo), CommitSha(args.commit.lower()), _now())
    print(run.dir)
    return 0


def cmd_run(args: argparse.Namespace) -> int | Refused:
    run = load_run(Path(args.run_dir))
    artifact = _artifact(args.artifact)
    if isinstance(run, Refused):
        return run
    if isinstance(artifact, Refused):
        return artifact
    command = " ".join(args.command).strip()
    if not command:
        return Refused("No command was given. Put it after `--`.")
    if args.timeout <= 0:
        return Refused(f"--timeout is {args.timeout}. Give a number of seconds above zero.")
    request = ObservationRequest(ShellCommand(command), artifact, _side(args.side), args.timeout)
    started = _now()
    outcome = redact_outcome(execute(request))
    observation = record(run, request, outcome, started, _now())
    print(_header(observation).replace("**", ""))
    print(f"--- stdout ({OBSERVATIONS}/{observation.id}.stdout)")
    sys.stdout.write(observation.stdout.decode(errors="replace"))
    print(f"--- stderr ({OBSERVATIONS}/{observation.id}.stderr)")
    sys.stdout.write(observation.stderr.decode(errors="replace"))
    return 0


def cmd_attach(args: argparse.Namespace) -> int | Refused:
    run = load_run(Path(args.run_dir))
    artifact = _artifact(args.artifact)
    if isinstance(run, Refused):
        return run
    if isinstance(artifact, Refused):
        return artifact
    observation = store(run, Path(args.file), artifact, _side(args.side), _now())
    if isinstance(observation, Refused):
        return observation
    print(_header(observation).replace("**", ""))
    return 0


def cmd_report(args: argparse.Namespace) -> int | Refused:
    run = load_run(Path(args.run_dir))
    if isinstance(run, Refused):
        return run
    draft_path = Path(args.draft)
    if not draft_path.is_file():
        return Refused(f"{draft_path} is not a file, so there is no draft to report.")
    draft = parse_draft(draft_path.read_text(), draft_path)
    if isinstance(draft, DraftRejected):
        return Refused(f"{draft.draft_path}: {draft.field} {draft.reason}.")
    report = resolve(draft, load_observations(run))
    if not isinstance(report, Report):
        return Refused(describe_failure(report, run))
    text = render(report, run)
    (run.dir / "report.md").write_text(text)
    sys.stdout.write(text)
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="subcommand", required=True)

    start = sub.add_parser("start", help="create a new evidence run and print its folder")
    start.add_argument("--repo", required=True)
    start.add_argument("--commit", required=True)

    run = sub.add_parser("run", help="run a command and record what it printed")
    run.add_argument("run_dir")
    run.add_argument("--artifact", required=True)
    run.add_argument("--side", choices=["before", "after"])
    run.add_argument("--timeout", type=float, default=DEFAULT_LIMIT_SECONDS)

    attach = sub.add_parser("attach", help="store a copy of a file, such as a screenshot")
    attach.add_argument("run_dir")
    attach.add_argument("file")
    attach.add_argument("--artifact", required=True)
    attach.add_argument("--side", choices=["before", "after"])

    report = sub.add_parser("report", help="render the report from a draft")
    report.add_argument("run_dir")
    report.add_argument("draft")

    # Everything after the first `--` is the command, so its own flags never reach argparse.
    command: list[str] = []
    if "--" in argv:
        split = argv.index("--")
        argv, command = argv[:split], argv[split + 1 :]
    args = parser.parse_args(argv)
    args.command = command
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    handlers = {"start": cmd_start, "run": cmd_run, "attach": cmd_attach, "report": cmd_report}
    result = handlers[args.subcommand](args)
    if isinstance(result, Refused):
        print(f"record.py: {result.sentence}", file=sys.stderr)
        return 2
    return result


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
