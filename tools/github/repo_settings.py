#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic>=2,<3"]
# ///
"""Report how each of my repos' security settings differ from one baseline, or apply it.

Run:
  uv run tools/github/repo_settings.py --check <repo>...   report each repo's drift, change nothing
  uv run tools/github/repo_settings.py --apply <repo>...   write each drifted setting, then read it

Each repo is `owner/name`, or a bare `name` for one of mine, so `hub` means `ooloth/hub`.

The baseline turns on Dependabot alerts and security updates, makes the default workflow token
read-only, stops Actions approving pull requests, and deletes head branches on merge. On a public
repo it also turns on secret scanning, push protection, private vulnerability reporting and
auto-merge, which a private repo on the free plan cannot have, so a private repo is never asked
for them. It requires actions pinned to a full commit SHA only once every workflow already pins
them, because requiring it earlier fails every run of an unpinned workflow.

`--check` sends only GET requests. `--apply` sends one write per drifted setting, reads the
settings again, and reports any that did not take. Either mode exits 1 when any repo drifted,
could not be read or refused a write, and reports every repo before it exits. It needs `gh`,
signed in as the owner of the repos.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from enum import Enum
from typing import Generic, Literal, NewType, TypeVar, assert_never

from pydantic import BaseModel, ValidationError

OWNER = "ooloth"

RepoName = NewType("RepoName", str)
"""A repo as `owner/name`."""

T = TypeVar("T")
E = TypeVar("E")


@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T


@dataclass(frozen=True)
class Err(Generic[E]):
    error: E


class Mode(Enum):
    CHECK = "check"
    APPLY = "apply"


class Visibility(Enum):
    PUBLIC = "public"
    PRIVATE = "private"


class Setting(Enum):
    """Each setting the baseline governs. The order is the order writes are sent in: GitHub turns
    on security updates only once alerts are on."""

    VULNERABILITY_ALERTS = "Dependabot alerts"
    SECURITY_FIXES = "Dependabot security updates"
    SECRET_SCANNING = "secret scanning"
    PUSH_PROTECTION = "secret scanning push protection"
    PRIVATE_REPORTING = "private vulnerability reporting"
    TOKEN_READ_ONLY = "read-only default workflow token"
    ACTIONS_CANNOT_APPROVE = "Actions cannot approve pull requests"
    SHA_PINNING = "actions must be pinned to a full commit SHA"
    AUTO_MERGE = "auto-merge allowed"
    DELETE_BRANCH = "head branches deleted on merge"


PUBLIC_ONLY = frozenset(
    {
        Setting.SECRET_SCANNING,
        Setting.PUSH_PROTECTION,
        Setting.PRIVATE_REPORTING,
        Setting.AUTO_MERGE,
    }
)
"""Settings a private repo on the free plan cannot have."""


@dataclass(frozen=True)
class ActionRef:
    """One `uses:` value in one workflow file."""

    workflow: str
    uses: str


@dataclass(frozen=True)
class RepoSettings:
    """What one repo has today. `values` holds only the settings its visibility can have."""

    repo: RepoName
    visibility: Visibility
    values: Mapping[Setting, bool]
    actions_enabled: bool
    unpinned: tuple[ActionRef, ...]


@dataclass(frozen=True)
class Baseline:
    """What one repo should have. A setting absent from `wanted` is left as it is."""

    wanted: Mapping[Setting, bool]


@dataclass(frozen=True)
class Drift:
    setting: Setting
    actual: bool
    wanted: bool


@dataclass(frozen=True)
class WriteRequest:
    """One write that sets `setting` to `value`."""

    setting: Setting
    value: bool
    method: Literal["PUT", "PATCH", "DELETE"]
    path: str
    body: Mapping[str, object] | None


@dataclass(frozen=True)
class GhCall:
    method: str
    path: str


@dataclass(frozen=True)
class GhFailure:
    """A `gh api` call that failed, kept whole so it can be rerun by hand."""

    call: GhCall
    status: int | None
    message: str


@dataclass(frozen=True)
class RepoUnreadable:
    repo: RepoName
    failure: GhFailure


@dataclass(frozen=True)
class InSync:
    settings: RepoSettings


@dataclass(frozen=True)
class Drifted:
    settings: RepoSettings
    drifts: tuple[Drift, ...]


@dataclass(frozen=True)
class Fixed:
    settings: RepoSettings
    drifts: tuple[Drift, ...]


@dataclass(frozen=True)
class WriteRefused:
    settings: RepoSettings
    request: WriteRequest
    failure: GhFailure


@dataclass(frozen=True)
class DidNotTake:
    settings: RepoSettings
    remaining: tuple[Drift, ...]


RepoReport = InSync | Drifted | Fixed | WriteRefused | DidNotTake | RepoUnreadable


# --- GitHub's responses, parsed at the boundary ---------------------------------------------


class _Status(BaseModel):
    status: Literal["enabled", "disabled"]


class _SecurityAndAnalysis(BaseModel):
    secret_scanning: _Status | None = None
    secret_scanning_push_protection: _Status | None = None


class _Repo(BaseModel):
    visibility: Literal["public", "private", "internal"]
    allow_auto_merge: bool
    delete_branch_on_merge: bool
    security_and_analysis: _SecurityAndAnalysis | None = None


class _Enabled(BaseModel):
    enabled: bool


class _ActionsPermissions(BaseModel):
    enabled: bool
    sha_pinning_required: bool = False


class _WorkflowPermissions(BaseModel):
    default_workflow_permissions: Literal["read", "write"]
    can_approve_pull_request_reviews: bool


class _ContentEntry(BaseModel):
    name: str
    path: str
    type: str


# --- Calling gh -------------------------------------------------------------------------------

_HTTP_STATUS = re.compile(r"\(HTTP (\d{3})\)")


class Gh:
    """Runs `gh api`. In check mode it refuses anything but GET, so a bug cannot write."""

    def __init__(self, mode: Mode) -> None:
        self.mode = mode

    def api(
        self,
        method: Literal["GET", "PUT", "PATCH", "DELETE"],
        path: str,
        body: Mapping[str, object] | None = None,
        raw: bool = False,
    ) -> Ok[str] | Err[GhFailure]:
        assert self.mode is Mode.APPLY or method == "GET", f"check mode tried {method} {path}"
        args = ["gh", "api", "-X", method, path]
        if raw:
            args += ["-H", "Accept: application/vnd.github.raw+json"]
        if body is not None:
            args += ["--input", "-"]
        return self._run(GhCall(method, path), args, json.dumps(body) if body is not None else None)

    def _run(self, call: GhCall, args: list[str], stdin: str | None) -> Ok[str] | Err[GhFailure]:
        try:
            done = subprocess.run(args, input=stdin, capture_output=True, text=True, check=False)
        except FileNotFoundError:
            return Err(
                GhFailure(call, None, "gh is not installed. Install it with `brew install gh`.")
            )
        if done.returncode == 0:
            return Ok(done.stdout)
        message = done.stderr.strip() or done.stdout.strip()
        match = _HTTP_STATUS.search(message)
        return Err(GhFailure(call, int(match.group(1)) if match else None, message))


# --- Reading ----------------------------------------------------------------------------------

M = TypeVar("M", bound=BaseModel)


def _parsed(gh: Gh, path: str, model: type[M]) -> Ok[M] | Err[GhFailure]:
    match gh.api("GET", path):
        case Ok(value=text):
            try:
                return Ok(model.model_validate_json(text))
            except ValidationError as error:
                return Err(GhFailure(GhCall("GET", path), None, f"unexpected response: {error}"))
        case Err() as failure:
            return failure


def _enabled_or_404(gh: Gh, path: str) -> Ok[bool] | Err[GhFailure]:
    """GitHub answers some "is this on?" endpoints with 404 when it is off."""
    match _parsed(gh, path, _Enabled):
        case Ok(value=parsed):
            return Ok(parsed.enabled)
        case Err(error=failure) if failure.status == 404:
            return Ok(False)
        case Err() as failure:
            return failure


def _alerts_enabled(gh: Gh, repo: RepoName) -> Ok[bool] | Err[GhFailure]:
    match gh.api("GET", f"repos/{repo}/vulnerability-alerts"):
        case Ok():
            return Ok(True)
        case Err(error=failure) if failure.status == 404:
            return Ok(False)
        case Err() as failure:
            return failure


_FULL_SHA = re.compile(r"[0-9a-f]{40}")
_USES = re.compile(r"""^\s*(?:-\s+)?uses:\s*["']?([^\s"'#]+)""")


def is_pinned(uses: str) -> bool:
    """Whether a `uses:` value names fixed code: a local action, an image by digest, or an action
    at a full commit SHA."""
    if uses.startswith("./"):
        return True
    if uses.startswith("docker://"):
        return "@sha256:" in uses
    _, at, ref = uses.rpartition("@")
    return bool(at) and _FULL_SHA.fullmatch(ref) is not None


def unpinned_actions(workflow: str, text: str) -> tuple[ActionRef, ...]:
    """Every `uses:` value in a workflow file that `is_pinned` rejects."""
    found = (_USES.match(line) for line in text.splitlines())
    return tuple(
        ActionRef(workflow, match.group(1))
        for match in found
        if match is not None and not is_pinned(match.group(1))
    )


def _unpinned_in_repo(gh: Gh, repo: RepoName) -> Ok[tuple[ActionRef, ...]] | Err[GhFailure]:
    path = f"repos/{repo}/contents/.github/workflows"
    match gh.api("GET", path):
        case Ok(value=text):
            pass
        case Err(error=failure) if failure.status == 404:
            return Ok(())
        case Err() as failure:
            return failure
    try:
        entries = [_ContentEntry.model_validate(item) for item in json.loads(text)]
    except (ValueError, ValidationError) as error:
        return Err(GhFailure(GhCall("GET", path), None, f"unexpected response: {error}"))
    found: list[ActionRef] = []
    for entry in entries:
        if entry.type != "file" or not entry.name.endswith((".yml", ".yaml")):
            continue
        match gh.api("GET", f"repos/{repo}/contents/{entry.path}", raw=True):
            case Ok(value=workflow):
                found += unpinned_actions(entry.path, workflow)
            case Err() as failure:
                return failure
    return Ok(tuple(found))


def read_settings(gh: Gh, repo: RepoName) -> Ok[RepoSettings] | Err[RepoUnreadable]:
    """Read every setting the baseline governs for one repo."""

    def unreadable(failure: GhFailure) -> Err[RepoUnreadable]:
        return Err(RepoUnreadable(repo, failure))

    match _parsed(gh, f"repos/{repo}", _Repo):
        case Ok(value=info):
            pass
        case Err(error=failure):
            return unreadable(failure)
    visibility = Visibility.PUBLIC if info.visibility == "public" else Visibility.PRIVATE
    values: dict[Setting, bool] = {
        Setting.DELETE_BRANCH: info.delete_branch_on_merge,
    }

    match _alerts_enabled(gh, repo):
        case Ok(value=on):
            values[Setting.VULNERABILITY_ALERTS] = on
        case Err(error=failure):
            return unreadable(failure)
    match _enabled_or_404(gh, f"repos/{repo}/automated-security-fixes"):
        case Ok(value=on):
            values[Setting.SECURITY_FIXES] = on
        case Err(error=failure):
            return unreadable(failure)
    match _parsed(gh, f"repos/{repo}/actions/permissions", _ActionsPermissions):
        case Ok(value=actions):
            values[Setting.SHA_PINNING] = actions.sha_pinning_required
        case Err(error=failure):
            return unreadable(failure)
    match _parsed(gh, f"repos/{repo}/actions/permissions/workflow", _WorkflowPermissions):
        case Ok(value=workflow):
            values[Setting.TOKEN_READ_ONLY] = workflow.default_workflow_permissions == "read"
            values[Setting.ACTIONS_CANNOT_APPROVE] = not workflow.can_approve_pull_request_reviews
        case Err(error=failure):
            return unreadable(failure)

    if visibility is Visibility.PUBLIC:
        scanning = info.security_and_analysis
        if (
            scanning is None
            or scanning.secret_scanning is None
            or scanning.secret_scanning_push_protection is None
        ):
            call = GhCall("GET", f"repos/{repo}")
            return unreadable(
                GhFailure(call, None, "a public repo returned no secret scanning status")
            )
        values[Setting.SECRET_SCANNING] = scanning.secret_scanning.status == "enabled"
        values[Setting.PUSH_PROTECTION] = (
            scanning.secret_scanning_push_protection.status == "enabled"
        )
        values[Setting.AUTO_MERGE] = info.allow_auto_merge
        match _enabled_or_404(gh, f"repos/{repo}/private-vulnerability-reporting"):
            case Ok(value=on):
                values[Setting.PRIVATE_REPORTING] = on
            case Err(error=failure):
                return unreadable(failure)

    match _unpinned_in_repo(gh, repo):
        case Ok(value=unpinned):
            pass
        case Err(error=failure):
            return unreadable(failure)

    return Ok(RepoSettings(repo, visibility, values, actions.enabled, unpinned))


# --- Comparing --------------------------------------------------------------------------------


def baseline(visibility: Visibility, unpinned: Sequence[ActionRef]) -> Baseline:
    """What a repo with this visibility and these unpinned actions should have."""
    wanted = {
        setting: True
        for setting in Setting
        if visibility is Visibility.PUBLIC or setting not in PUBLIC_ONLY
    }
    if unpinned:
        del wanted[Setting.SHA_PINNING]
    return Baseline(wanted)


def drift(settings: RepoSettings, wanted: Baseline) -> tuple[Drift, ...]:
    """Each setting whose value differs from the baseline, in `Setting` order."""
    drifts: list[Drift] = []
    for setting in Setting:
        if setting not in wanted.wanted:
            continue
        assert setting in settings.values, f"{settings.repo}: {setting.value} was never read"
        if settings.values[setting] != wanted.wanted[setting]:
            drifts.append(Drift(setting, settings.values[setting], wanted.wanted[setting]))
    return tuple(drifts)


def _request(
    settings: RepoSettings, wanted: Baseline, setting: Setting, value: bool
) -> WriteRequest:
    repo = settings.repo
    on_off: Literal["PUT", "DELETE"] = "PUT" if value else "DELETE"
    status = "enabled" if value else "disabled"
    match setting:
        case Setting.VULNERABILITY_ALERTS:
            return WriteRequest(setting, value, on_off, f"repos/{repo}/vulnerability-alerts", None)
        case Setting.SECURITY_FIXES:
            path = f"repos/{repo}/automated-security-fixes"
            return WriteRequest(setting, value, on_off, path, None)
        case Setting.PRIVATE_REPORTING:
            path = f"repos/{repo}/private-vulnerability-reporting"
            return WriteRequest(setting, value, on_off, path, None)
        case Setting.SECRET_SCANNING:
            body = {"security_and_analysis": {"secret_scanning": {"status": status}}}
            return WriteRequest(setting, value, "PATCH", f"repos/{repo}", body)
        case Setting.PUSH_PROTECTION:
            body = {
                "security_and_analysis": {"secret_scanning_push_protection": {"status": status}}
            }
            return WriteRequest(setting, value, "PATCH", f"repos/{repo}", body)
        case Setting.AUTO_MERGE:
            return WriteRequest(
                setting, value, "PATCH", f"repos/{repo}", {"allow_auto_merge": value}
            )
        case Setting.DELETE_BRANCH:
            body = {"delete_branch_on_merge": value}
            return WriteRequest(setting, value, "PATCH", f"repos/{repo}", body)
        case Setting.SHA_PINNING:
            # `enabled` is required, so the repo's current value is sent back unchanged.
            body = {"enabled": settings.actions_enabled, "sha_pinning_required": value}
            return WriteRequest(setting, value, "PUT", f"repos/{repo}/actions/permissions", body)
        case Setting.TOKEN_READ_ONLY | Setting.ACTIONS_CANNOT_APPROVE:
            # One endpoint holds both, so each write sends both: the one being fixed, and the other
            # at the baseline's value.
            read_only = (
                value
                if setting is Setting.TOKEN_READ_ONLY
                else wanted.wanted[Setting.TOKEN_READ_ONLY]
            )
            cannot_approve = (
                value
                if setting is Setting.ACTIONS_CANNOT_APPROVE
                else wanted.wanted[Setting.ACTIONS_CANNOT_APPROVE]
            )
            body = {
                "default_workflow_permissions": "read" if read_only else "write",
                "can_approve_pull_request_reviews": not cannot_approve,
            }
            path = f"repos/{repo}/actions/permissions/workflow"
            return WriteRequest(setting, value, "PUT", path, body)
        case _:
            assert_never(setting)


def requests_for(
    settings: RepoSettings, wanted: Baseline, drifts: Sequence[Drift]
) -> tuple[WriteRequest, ...]:
    """One write per drift, in `Setting` order."""
    requests = tuple(_request(settings, wanted, d.setting, d.wanted) for d in drifts)
    for request in requests:
        assert request.setting in wanted.wanted, f"{request.setting.value} is outside the baseline"
    return requests


# --- Running ----------------------------------------------------------------------------------


def check_repo(gh: Gh, repo: RepoName) -> RepoReport:
    match read_settings(gh, repo):
        case Ok(value=settings):
            pass
        case Err(error=unreadable):
            return unreadable
    drifts = drift(settings, baseline(settings.visibility, settings.unpinned))
    return Drifted(settings, drifts) if drifts else InSync(settings)


def apply_repo(gh: Gh, repo: RepoName) -> RepoReport:
    match read_settings(gh, repo):
        case Ok(value=settings):
            pass
        case Err(error=unreadable):
            return unreadable
    wanted = baseline(settings.visibility, settings.unpinned)
    drifts = drift(settings, wanted)
    if not drifts:
        return InSync(settings)
    for request in requests_for(settings, wanted, drifts):
        match gh.api(request.method, request.path, request.body):
            case Ok():
                pass
            case Err(error=failure):
                return WriteRefused(settings, request, failure)
    match read_settings(gh, repo):
        case Ok(value=after):
            pass
        case Err(error=unreadable):
            return unreadable
    remaining = drift(after, baseline(after.visibility, after.unpinned))
    return DidNotTake(after, remaining) if remaining else Fixed(after, drifts)


def _on(value: bool) -> str:
    return "on" if value else "off"


def describe(report: RepoReport) -> str:
    """The lines printed for one repo."""
    match report:
        case RepoUnreadable(repo=repo, failure=failure):
            return (
                f"❌ {repo}: could not read its settings. `gh api -X {failure.call.method} "
                f"{failure.call.path}` failed: {failure.message}"
            )
        case InSync(settings=settings):
            lines = [f"✅ {settings.repo}: matches the baseline"]
        case Drifted(settings=settings, drifts=drifts):
            lines = [f"⚠️  {settings.repo}: {len(drifts)} setting(s) differ from the baseline"]
            lines += [
                f"   {d.setting.value}: {_on(d.actual)}, wanted {_on(d.wanted)}" for d in drifts
            ]
            lines.append("   Run with --apply to change them.")
        case Fixed(settings=settings, drifts=drifts):
            lines = [f"🔧 {settings.repo}: changed {len(drifts)} setting(s) to match the baseline"]
            lines += [f"   {d.setting.value}: now {_on(d.wanted)}" for d in drifts]
        case WriteRefused(settings=settings, request=request, failure=failure):
            lines = [
                f"❌ {settings.repo}: GitHub refused to turn {request.setting.value} "
                f"{_on(request.value)}. `gh api -X {request.method} {request.path}` failed: "
                f"{failure.message}",
                "   Settings after this one were not attempted. Fix the cause and rerun --apply.",
            ]
        case DidNotTake(settings=settings, remaining=remaining):
            lines = [f"❌ {settings.repo}: GitHub accepted the writes but these still differ:"]
            lines += [
                f"   {d.setting.value}: {_on(d.actual)}, wanted {_on(d.wanted)}" for d in remaining
            ]
            lines.append("   The repo's plan may not allow them. Check its settings page.")
        case _:
            assert_never(report)
    if settings.unpinned:
        listed = ", ".join(f"{a.uses} in {a.workflow}" for a in settings.unpinned)
        lines.append(
            f"   SHA pinning is not required yet, because these actions are unpinned: {listed}"
        )
    return "\n".join(lines)


def succeeded(report: RepoReport) -> bool:
    match report:
        case InSync() | Fixed():
            return True
        case Drifted() | WriteRefused() | DidNotTake() | RepoUnreadable():
            return False
        case _:
            assert_never(report)


_REPO_PART = r"[A-Za-z0-9_.-]+"
_REPO_ARG = re.compile(rf"(?:({_REPO_PART})/)?({_REPO_PART})")


def repo_name(arg: str) -> RepoName:
    """Reads `owner/name`, or a bare `name` as one of mine. argparse reports the ValueError."""
    match = _REPO_ARG.fullmatch(arg)
    if match is None:
        raise ValueError(arg)
    owner, name = match.groups()
    return RepoName(f"{owner or OWNER}/{name}")


repo_name.__name__ = "owner/name"  # argparse names the type this way in its error


@dataclass(frozen=True)
class Args:
    mode: Mode
    repos: tuple[RepoName, ...]


def parse_args(argv: Sequence[str]) -> Args:
    parser = argparse.ArgumentParser(
        description=(__doc__ or "").split("\n\n")[0],
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--check", action="store_true", help="report drift and change nothing")
    modes.add_argument("--apply", action="store_true", help="write each drifted setting")
    parser.add_argument(
        "repos",
        nargs="+",
        type=repo_name,
        metavar="repo",
        help=f"a repo as owner/name, or a bare name for one of {OWNER}'s",
    )
    args = parser.parse_args(argv)
    return Args(Mode.APPLY if args.apply else Mode.CHECK, tuple(args.repos))


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    mode = args.mode
    gh = Gh(mode)
    reports: list[RepoReport] = []
    for repo in args.repos:
        match mode:
            case Mode.CHECK:
                report = check_repo(gh, repo)
            case Mode.APPLY:
                report = apply_repo(gh, repo)
            case _:
                assert_never(mode)
        print(describe(report), flush=True)
        reports.append(report)
    return 0 if all(succeeded(report) for report in reports) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
