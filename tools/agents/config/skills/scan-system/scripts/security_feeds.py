#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic>=2"]
# ///
"""Read a repo's GitHub security alert feeds, and cross-check them against local scanners.

Every feed ends in one definite result: counted, turned off, or failed to read. An empty answer is
never reported as "no alerts" on its own, because GitHub can return an empty list for reasons that
have nothing to do with the code: an alert feed it has not populated yet, a filter value it
silently ignores (state=all returns nothing; severity=bogus returns everything). So for each
lockfile with a local scanner, the script also runs that scanner and compares the two on one
question only: does each source find none, or some? The counts themselves differ by design (GitHub
counts alerts, npm audit counts packages, and GitHub keeps fixed alerts open until it rescans).

Read only: GitHub is queried with GET requests, and each scanner runs in a mode that changes
nothing. A scanner can still send data to a third party, which its line names.

Usage:
  security_feeds.py OWNER/REPO [--path DIR]

  --path is where to look for lockfiles (default: the current directory).

Exits 1 when a feed or a scan could not be read, so its result is unknown. A disagreement between
sources exits 0: it is a finding to report, not a failure of this script.

To support another ecosystem, add a Scanner to SCANNERS.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Literal, assert_never

from pydantic import BaseModel, ConfigDict, TypeAdapter, ValidationError

FeedName = Literal["dependabot", "code-scanning", "secret-scanning"]

# The only query parameters this script sends. GitHub answers an unknown value with a plausible
# result rather than an error, so a typo here would look exactly like a real answer.
DOCUMENTED_FILTERS: dict[str, frozenset[str]] = {
    "state": frozenset({"open"}),
    "per_page": frozenset({"100"}),
}
FILTERS = {"state": "open", "per_page": "100"}


@dataclass(frozen=True)
class Feed:
    name: FeedName
    endpoint: str
    # What GitHub says when the feature is turned off for the repo, as of 2026-10-23
    turned_off_message: str


FEEDS: tuple[Feed, ...] = (
    Feed("dependabot", "dependabot/alerts", "Dependabot alerts are disabled for this repository."),
    Feed(
        "code-scanning", "code-scanning/alerts", "Code scanning is not enabled for this repository."
    ),
    Feed(
        "secret-scanning",
        "secret-scanning/alerts",
        "Secret scanning is disabled on this repository.",
    ),
)


class _Package(BaseModel):
    model_config = ConfigDict(extra="ignore")
    ecosystem: str
    name: str


class _Dependency(BaseModel):
    model_config = ConfigDict(extra="ignore")
    package: _Package


class _Alert(BaseModel):
    """The fields every alert has, plus the package for Dependabot alerts."""

    model_config = ConfigDict(extra="ignore")
    number: int
    state: str
    dependency: _Dependency | None = None


_PAGES = TypeAdapter(list[list[_Alert]])


@dataclass(frozen=True)
class Alert:
    ecosystem: str | None


@dataclass(frozen=True)
class Counted:
    feed: FeedName
    alerts: tuple[Alert, ...]
    command: str


@dataclass(frozen=True)
class TurnedOff:
    feed: FeedName
    message: str


@dataclass(frozen=True)
class ReadFailed:
    feed: FeedName
    reason: str
    command: str


FeedResult = Counted | TurnedOff | ReadFailed


@dataclass(frozen=True)
class Scanned:
    ecosystem: str
    vulnerable_packages: int
    command: str
    sent_to: str


@dataclass(frozen=True)
class NoScanner:
    ecosystem: str
    tool: str


@dataclass(frozen=True)
class ScanFailed:
    ecosystem: str
    reason: str
    command: str


LocalScan = Scanned | NoScanner | ScanFailed


@dataclass(frozen=True)
class Agree:
    ecosystem: str
    github_alerts: int
    local_packages: int


@dataclass(frozen=True)
class Disagree:
    ecosystem: str
    github: str
    local_packages: int


@dataclass(frozen=True)
class CannotCompare:
    ecosystem: str
    reason: str


CrossCheck = Agree | Disagree | CannotCompare


@dataclass(frozen=True)
class Scanner:
    """A local scanner for one ecosystem, run against its lockfile without changing anything."""

    ecosystem: str  # as Dependabot names it in dependency.package.ecosystem
    lockfiles: tuple[str, ...]
    tool: str
    command: tuple[str, ...]
    sent_to: str
    count_vulnerable_packages: Callable[
        [str], int | str
    ]  # a count, or why the output isn't a report


def _count_npm_audit(stdout: str) -> int | str:
    try:
        report = json.loads(stdout)
    except json.JSONDecodeError:
        return f"output is not JSON: {stdout.strip()[:200]}"
    match report:
        case {"vulnerabilities": dict() as vulnerabilities}:
            return len(vulnerabilities)
        case {"error": {"summary": str() as summary}}:
            return summary
        case _:
            return "output has no vulnerabilities field"


SCANNERS: tuple[Scanner, ...] = (
    Scanner(
        ecosystem="npm",
        lockfiles=("package-lock.json",),
        tool="npm",
        command=("npm", "audit", "--json", "--package-lock-only"),
        sent_to="sent package-lock.json to the npm registry (registry.npmjs.org)",
        count_vulnerable_packages=_count_npm_audit,
    ),
)


def feed_url(repo: str, feed: Feed) -> str:
    for key, value in FILTERS.items():
        if value not in DOCUMENTED_FILTERS[key]:
            raise AssertionError(
                f"undocumented filter {key}={value}: GitHub would answer it silently"
            )
    query = "&".join(f"{key}={value}" for key, value in FILTERS.items())
    return f"repos/{repo}/{feed.endpoint}?{query}"


_GH_ERROR = re.compile(r"gh: (?P<message>.*) \(HTTP (?P<status>\d{3})\)")


def read_feed(repo: str, feed: Feed) -> FeedResult:
    command = ("gh", "api", feed_url(repo, feed), "--paginate", "--slurp")
    shown = " ".join(command)
    if shutil.which("gh") is None:
        return ReadFailed(feed.name, "gh is not installed", shown)

    done = subprocess.run(command, capture_output=True, text=True, check=False)
    return classify_gh_response(feed, done.returncode, done.stdout, done.stderr, shown)


def classify_gh_response(
    feed: Feed, returncode: int, stdout: str, stderr: str, command: str
) -> FeedResult:
    """Turn one `gh api --paginate --slurp` call into a definite result for the feed."""
    if returncode != 0:
        # gh leaves a half-written body on stdout when a request fails, so only stderr is read
        error = _GH_ERROR.search(stderr)
        if error is None:
            return ReadFailed(feed.name, f"gh exited {returncode}: {stderr.strip()[:300]}", command)
        message, status = error["message"], int(error["status"])
        if status in (403, 404) and message.startswith(feed.turned_off_message):
            return TurnedOff(feed.name, message)
        return ReadFailed(feed.name, f"HTTP {status}: {message}", command)

    try:
        pages = _PAGES.validate_json(stdout)
    except ValidationError as e:
        return ReadFailed(
            feed.name, f"response is not a list of alerts: {e.errors()[0]['msg']}", command
        )

    alerts = tuple(
        Alert(a.dependency.package.ecosystem if a.dependency else None)
        for page in pages
        for a in page
    )
    if len(alerts) != sum(len(page) for page in pages):
        raise AssertionError("an alert was dropped while flattening pages")
    return Counted(feed.name, alerts, command)


def scan(scanner: Scanner, project: Path) -> LocalScan:
    shown = " ".join(scanner.command)
    if shutil.which(scanner.tool) is None:
        return NoScanner(scanner.ecosystem, scanner.tool)
    done = subprocess.run(scanner.command, capture_output=True, text=True, check=False, cwd=project)
    match scanner.count_vulnerable_packages(done.stdout):
        case int() as count:
            return Scanned(scanner.ecosystem, count, shown, scanner.sent_to)
        case str() as reason:
            return ScanFailed(scanner.ecosystem, reason, shown)


def cross_check(dependabot: FeedResult, local: LocalScan) -> CrossCheck:
    match local:
        case NoScanner(ecosystem, tool):
            return CannotCompare(
                ecosystem, f"{tool} is not installed, so GitHub is the only source"
            )
        case ScanFailed(ecosystem, _, _):
            return CannotCompare(ecosystem, "the local scan failed, so GitHub is the only source")
        case Scanned(ecosystem, local_packages, _, _):
            pass
        case _:
            assert_never(local)

    match dependabot:
        case ReadFailed():
            return CannotCompare(ecosystem, "the Dependabot feed could not be read")
        case TurnedOff():
            if local_packages > 0:
                return Disagree(ecosystem, "Dependabot turned off", local_packages)
            return Agree(ecosystem, 0, 0)
        case Counted(_, alerts, _):
            github_alerts = sum(1 for alert in alerts if alert.ecosystem == ecosystem)
        case _:
            assert_never(dependabot)

    if (github_alerts == 0) != (local_packages == 0):
        return Disagree(ecosystem, f"GitHub {github_alerts} open alerts", local_packages)
    return Agree(ecosystem, github_alerts, local_packages)


def render_feed(result: FeedResult) -> str:
    match result:
        case Counted(feed, alerts, command):
            return f"{feed:<16} counted {len(alerts)} open alerts  ({command})"
        case TurnedOff(feed, message):
            return f"{feed:<16} turned off: {message}"
        case ReadFailed(feed, reason, command):
            return f"{feed:<16} failed: {reason}  (rerun: {command})"
        case _:
            assert_never(result)


def render_scan(result: LocalScan) -> str:
    match result:
        case Scanned(ecosystem, count, command, sent_to):
            return f"{ecosystem} audit{'':<6} scanned: {count} vulnerable packages; {sent_to}  ({command})"
        case NoScanner(ecosystem, tool):
            return f"{ecosystem} audit{'':<6} not run: {tool} is not installed"
        case ScanFailed(ecosystem, reason, command):
            return f"{ecosystem} audit{'':<6} failed: {reason}  (rerun: {command})"
        case _:
            assert_never(result)


def render_check(result: CrossCheck) -> str:
    match result:
        case Agree(ecosystem, github_alerts, local_packages):
            return (
                f"{ecosystem} cross-check agree: GitHub {github_alerts} open alerts, {ecosystem} audit "
                f"{local_packages} packages (only none versus some is compared)"
            )
        case Disagree(ecosystem, github, local_packages):
            return f"{ecosystem} cross-check DISAGREE: {github}, {ecosystem} audit {local_packages} vulnerable packages"
        case CannotCompare(ecosystem, reason):
            return f"{ecosystem} cross-check cannot compare: {reason}"
        case _:
            assert_never(result)


_REPO = re.compile(r"[A-Za-z0-9-]+/[A-Za-z0-9._-]+")


def _owner_slash_name(value: str) -> str:
    """Reject anything but OWNER/NAME before it reaches a URL."""
    if _REPO.fullmatch(value) is None or value.split("/")[1] in (".", ".."):
        raise argparse.ArgumentTypeError(f"expected OWNER/NAME, got {value!r}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Read GitHub security alert feeds and cross-check them."
    )
    parser.add_argument("repo", type=_owner_slash_name, help="OWNER/NAME")
    parser.add_argument("--path", type=Path, default=Path.cwd(), help="where to look for lockfiles")
    args = parser.parse_args()

    feeds = {feed.name: read_feed(args.repo, feed) for feed in FEEDS}
    for result in feeds.values():
        print(render_feed(result))

    present = [
        s for s in SCANNERS if any((args.path / lockfile).is_file() for lockfile in s.lockfiles)
    ]
    scans = [scan(scanner, args.path) for scanner in present]
    for local in scans:
        print(render_scan(local))
        print(render_check(cross_check(feeds["dependabot"], local)))
    if not present:
        looked_for = ", ".join(lockfile for s in SCANNERS for lockfile in s.lockfiles)
        print(
            f"cross-check      no lockfile with a local scanner in {args.path} (looked for: {looked_for})"
        )

    unknown = any(isinstance(r, ReadFailed) for r in feeds.values()) or any(
        isinstance(s, ScanFailed) for s in scans
    )
    return 1 if unknown else 0


if __name__ == "__main__":
    sys.exit(main())
