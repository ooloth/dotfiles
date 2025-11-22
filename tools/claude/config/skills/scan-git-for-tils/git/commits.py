"""GitHub commit fetching utilities."""

from __future__ import annotations

import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta

from git.formatting import format_relative_date
from git.types import Commit


def get_github_username() -> str:
    """Get the authenticated GitHub username."""
    result = subprocess.run(
        ["gh", "api", "user", "--jq", ".login"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def get_commit_files(repo: str, sha: str) -> list[str]:
    """Get files changed in a commit."""
    if not sha:
        return []

    result = subprocess.run(
        [
            "gh", "api", f"repos/{repo}/commits/{sha}",
            "--jq", "[.files[].filename]",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        return []

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return []


def get_commits(days: int, username: str) -> list[Commit]:
    """Fetch commits from GitHub API."""
    since_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Search for commits by the user
    query = f"author:{username} committer-date:>={since_date[:10]}"

    result = subprocess.run(
        [
            "gh", "api", "search/commits",
            "-X", "GET",
            "-f", f"q={query}",
            "-f", "sort=committer-date",
            "-f", "per_page=100",
            "--jq", ".items",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        # Try alternative: list events
        return get_commits_from_events(days, username)

    try:
        items = json.loads(result.stdout)
    except json.JSONDecodeError:
        return []

    # Build commits list without files first
    commits = []
    for item in items:
        commit_data = item.get("commit", {})
        repo = item.get("repository", {}).get("full_name", "unknown")

        commit_date = commit_data.get("committer", {}).get("date", "")
        message_lines = commit_data.get("message", "").split("\n")

        commits.append(Commit(
            hash=item.get("sha", "")[:7],
            full_hash=item.get("sha", ""),
            subject=message_lines[0],
            body="\n".join(message_lines[1:]).strip(),
            date=format_relative_date(commit_date),
            iso_date=commit_date[:10] if commit_date else "",
            repo=repo,
            files=[],
            url=item.get("html_url", ""),
        ))

    # Fetch files in parallel (limit concurrency to avoid rate limits)
    if commits:
        with ThreadPoolExecutor(max_workers=5) as executor:
            future_to_commit = {
                executor.submit(get_commit_files, c.repo, c.full_hash): c
                for c in commits
            }
            for future in as_completed(future_to_commit):
                commit = future_to_commit[future]
                try:
                    commit.files = future.result()
                except Exception as e:
                    print(f"Warning: Failed to fetch files for {commit.hash}: {e}", file=sys.stderr)
                    commit.files = []

    return commits


def get_commits_from_events(days: int, username: str) -> list[Commit]:
    """Fallback: get commits from user events."""
    result = subprocess.run(
        [
            "gh", "api", f"users/{username}/events",
            "--jq", '[.[] | select(.type == "PushEvent")]',
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(
            f"Error: Failed to fetch user events via gh api "
            f"(exit code {result.returncode}): {result.stderr.strip()}",
            file=sys.stderr,
        )
        return []

    try:
        events = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("Error: Failed to parse JSON output from gh api user events.", file=sys.stderr)
        return []

    commits = []
    seen_hashes = set()
    cutoff = datetime.now() - timedelta(days=days)

    for event in events:
        created = datetime.fromisoformat(event.get("created_at", "").replace("Z", "+00:00"))
        if created.replace(tzinfo=None) < cutoff:
            continue

        repo = event.get("repo", {}).get("name", "unknown")

        for commit_data in event.get("payload", {}).get("commits", []):
            sha = commit_data.get("sha", "")
            if sha in seen_hashes:
                continue
            seen_hashes.add(sha)

            message = commit_data.get("message", "")
            message_lines = message.split("\n")
            event_date = event.get("created_at", "")

            commits.append(Commit(
                hash=sha[:7],
                full_hash=sha,
                subject=message_lines[0],
                body="\n".join(message_lines[1:]).strip(),
                date=format_relative_date(event_date),
                iso_date=event_date[:10] if event_date else "",
                repo=repo,
                files=[],  # Events don't include files
                url=f"https://github.com/{repo}/commit/{sha}",
            ))

    return commits
