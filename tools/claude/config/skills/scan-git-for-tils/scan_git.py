#!/usr/bin/env python3
"""
Scan GitHub commit history for TIL-worthy commits.

Usage:
    python3 scan_git.py [days]

Arguments:
    days: Number of days to look back (default: 30)

Output:
    JSON with commits for Claude to evaluate

Requires:
    - gh CLI installed and authenticated
    - op CLI installed and authenticated (1Password)
"""

import subprocess
import sys
import json
import urllib.request
import urllib.error
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed

# 1Password paths
OP_NOTION_TOKEN = "op://Scripts/Notion/api-access-token"

# Notion database IDs
NOTION_ASSESSED_COMMITS_DB = "928fcd9e47a84f98824790ac5a6d37ca"


def get_op_secret(path: str) -> str:
    """Fetch a secret from 1Password."""
    result = subprocess.run(
        ["op", "read", path],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def get_assessed_commits_from_notion() -> set[str]:
    """Fetch all assessed commit hashes from Notion database."""
    token = get_op_secret(OP_NOTION_TOKEN)
    if not token:
        return set()

    url = f"https://api.notion.com/v1/databases/{NOTION_ASSESSED_COMMITS_DB}/query"
    headers = {
        "Authorization": f"Bearer {token}",
        "Notion-Version": "2022-06-28",
        "Content-Type": "application/json",
    }

    assessed_hashes = set()
    has_more = True
    start_cursor = None

    while has_more:
        body = {}
        if start_cursor:
            body["start_cursor"] = start_cursor

        req = urllib.request.Request(
            url,
            data=json.dumps(body).encode("utf-8"),
            headers=headers,
            method="POST",
        )

        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode("utf-8"))
        except urllib.error.URLError:
            break

        for page in data.get("results", []):
            # Commit Hash is the title property
            title_prop = page.get("properties", {}).get("Commit Hash", {})
            title_content = title_prop.get("title", [])
            if title_content:
                commit_hash = title_content[0].get("plain_text", "")
                if commit_hash:
                    assessed_hashes.add(commit_hash)

        has_more = data.get("has_more", False)
        start_cursor = data.get("next_cursor")

    return assessed_hashes


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


def get_commits(days: int, username: str) -> list[dict]:
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
        commit = item.get("commit", {})
        repo = item.get("repository", {}).get("full_name", "unknown")

        commit_date = commit.get("committer", {}).get("date", "")
        commits.append({
            "hash": item.get("sha", "")[:7],
            "full_hash": item.get("sha", ""),
            "subject": commit.get("message", "").split("\n")[0],
            "body": "\n".join(commit.get("message", "").split("\n")[1:]).strip(),
            "date": format_relative_date(commit_date),
            "iso_date": commit_date[:10] if commit_date else "",  # YYYY-MM-DD
            "repo": repo,
            "files": [],
            "url": item.get("html_url", ""),
        })

    # Fetch files in parallel (limit concurrency to avoid rate limits)
    if commits:
        with ThreadPoolExecutor(max_workers=5) as executor:
            future_to_commit = {
                executor.submit(get_commit_files, c["repo"], c["full_hash"]): c
                for c in commits
            }
            for future in as_completed(future_to_commit):
                commit = future_to_commit[future]
                try:
                    commit["files"] = future.result()
                except Exception as e:
                    print(f"Warning: Failed to fetch files for {commit['hash']}: {e}", file=sys.stderr)
                    commit["files"] = []

    return commits


def get_commits_from_events(days: int, username: str) -> list[dict]:
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
        print(f"Error: Failed to fetch user events via gh api (exit code {result.returncode}): {result.stderr.strip()}", file=sys.stderr)
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
            event_date = event.get("created_at", "")
            commits.append({
                "hash": sha[:7],
                "full_hash": sha,
                "subject": message.split("\n")[0],
                "body": "\n".join(message.split("\n")[1:]).strip(),
                "date": format_relative_date(event_date),
                "iso_date": event_date[:10] if event_date else "",
                "repo": repo,
                "files": [],  # Events don't include files
                "url": f"https://github.com/{repo}/commit/{sha}",
            })

    return commits


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


def format_relative_date(iso_date: str) -> str:
    """Convert ISO date to relative format."""
    if not iso_date:
        return "unknown"

    try:
        dt = datetime.fromisoformat(iso_date.replace("Z", "+00:00"))
        now = datetime.now(dt.tzinfo)
        diff = now - dt

        if diff.days == 0:
            hours = diff.seconds // 3600
            if hours == 0:
                return "just now"
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif diff.days == 1:
            return "yesterday"
        elif diff.days < 7:
            return f"{diff.days} days ago"
        elif diff.days < 30:
            weeks = diff.days // 7
            return f"{weeks} week{'s' if weeks != 1 else ''} ago"
        else:
            months = diff.days // 30
            return f"{months} month{'s' if months != 1 else ''} ago"
    except (ValueError, TypeError):
        return "unknown"


def should_skip_commit(commit: dict) -> bool:
    """Check if commit should be filtered out entirely."""
    subject = commit["subject"].lower()

    # Skip dependency bot commits
    if "dependabot" in subject or ("bump" in subject and "from" in subject):
        return True

    # Skip merge commits
    if subject.startswith("merge"):
        return True

    return False




def format_markdown(commits: list[dict], days: int, new_count: int, total_count: int) -> str:
    """Format commits as markdown for Claude to evaluate."""
    header = f"Git commits from last {days} days:\n"

    if total_count > 0 and new_count == 0:
        return f"{header}\nNo new commits to assess ({total_count} commits already reviewed)."

    if not commits:
        return f"{header}\nNo commits found. Try increasing the date range."

    lines = [header]
    if new_count < total_count:
        lines.append(f"({new_count} new, {total_count - new_count} already reviewed)\n")

    for i, commit in enumerate(commits, 1):
        files_str = ", ".join(commit["files"][:5]) if commit["files"] else "(no files)"
        if len(commit["files"]) > 5:
            files_str += f" (+{len(commit['files']) - 5} more)"

        lines.append(f"{i}. [{commit['repo']}] {commit['subject']}")
        lines.append(f"   Hash: {commit['hash']} (index: {i-1}) | Date: {commit['date']}")
        if commit["body"]:
            body_preview = commit["body"][:200] + "..." if len(commit["body"]) > 200 else commit["body"]
            lines.append(f"   Body: {body_preview}")
        lines.append(f"   Files: {files_str}")
        lines.append(f"   URL: {commit['url']}")
        lines.append("")

    return "\n".join(lines)


def main():
    # Parse arguments
    days = 30
    if len(sys.argv) > 1:
        try:
            days = int(sys.argv[1])
        except ValueError:
            pass

    # Fetch assessed commits from Notion
    assessed_hashes = get_assessed_commits_from_notion()

    # Get GitHub username
    username = get_github_username()
    if not username:
        print(json.dumps({
            "error": "Could not get GitHub username. Is `gh` authenticated?",
            "markdown": "",
            "new_commits": []
        }))
        sys.exit(1)

    # Get commits
    commits = get_commits(days, username)
    total_count = len(commits)

    if not commits:
        print(json.dumps({
            "markdown": format_markdown([], days, 0, 0),
            "new_commits": []
        }))
        sys.exit(0)

    # Filter out already assessed commits and skippable commits
    new_commits = [
        c for c in commits
        if c["full_hash"] not in assessed_hashes and not should_skip_commit(c)
    ]
    new_count = len(new_commits)

    # Prepare output - all commits for Claude to evaluate
    output = {
        "markdown": format_markdown(new_commits, days, new_count, total_count),
        "new_commits": [
            {
                "hash": c["full_hash"],
                "message": c["subject"],
                "repo": c["repo"],
                "date": c["iso_date"]
            }
            for c in new_commits
        ]
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
