#!/usr/bin/env python3
"""
Scan GitHub commit history for TIL-worthy commits.

Usage:
    python3 scan_git.py [days] [--assessed-hashes hash1,hash2,...]

Arguments:
    days: Number of days to look back (default: 30)
    --assessed-hashes: Comma-separated list of already-assessed commit hashes

Output:
    JSON with suggestions and new commits to mark as assessed

Requires:
    - gh CLI installed and authenticated
"""

import subprocess
import sys
import json
import re
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed


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

        commits.append({
            "hash": item.get("sha", "")[:7],
            "full_hash": item.get("sha", ""),
            "subject": commit.get("message", "").split("\n")[0],
            "body": "\n".join(commit.get("message", "").split("\n")[1:]).strip(),
            "date": format_relative_date(commit.get("committer", {}).get("date", "")),
            "repo": repo,
            "files": [],
            "url": item.get("html_url", ""),
        })

    # Fetch files in parallel (limit concurrency to avoid rate limits)
    if commits:
        with ThreadPoolExecutor(max_workers=15) as executor:
            future_to_commit = {
                executor.submit(get_commit_files, c["repo"], c["full_hash"]): c
                for c in commits
            }
            for future in as_completed(future_to_commit):
                commit = future_to_commit[future]
                try:
                    commit["files"] = future.result()
                except Exception:
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
        return []

    try:
        events = json.loads(result.stdout)
    except json.JSONDecodeError:
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
            commits.append({
                "hash": sha[:7],
                "full_hash": sha,
                "subject": message.split("\n")[0],
                "body": "\n".join(message.split("\n")[1:]).strip(),
                "date": format_relative_date(event.get("created_at", "")),
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


def score_commit(commit: dict) -> int:
    """Score a commit's TIL potential (0-100)."""
    score = 0
    subject = commit["subject"].lower()
    body = commit["body"].lower()
    files = commit["files"]

    # Skip dependency bot commits
    if "dependabot" in subject or ("bump" in subject and "from" in subject):
        return 0

    # Skip merge commits
    if subject.startswith("merge"):
        return 0

    # Fix-related keywords (+30)
    fix_keywords = ["fix", "resolve", "workaround", "gotcha", "issue", "bug", "correct"]
    if any(kw in subject for kw in fix_keywords):
        score += 30

    # Configuration files (+20)
    config_patterns = [
        r"\..*rc$", r"\.config", r"\.json$", r"\.yaml$", r"\.yml$",
        r"\.toml$", r"\.env", r"Makefile", r"Dockerfile",
    ]
    for f in files:
        if any(re.search(pat, f) for pat in config_patterns):
            score += 20
            break

    # Detailed commit message (+15)
    full_message = commit["subject"] + " " + commit["body"]
    if len(full_message) > 100 or commit["body"]:
        score += 15

    # Learning indicators (+20)
    learning_keywords = ["learn", "discover", "realize", "turns out", "actually", "til", "today i learned"]
    if any(kw in subject or kw in body for kw in learning_keywords):
        score += 20

    # How-to indicators (+15)
    howto_keywords = ["how to", "enable", "configure", "setup", "set up", "install"]
    if any(kw in subject or kw in body for kw in howto_keywords):
        score += 15

    # Multiple files suggests complexity (+10)
    if 2 <= len(files) <= 5:
        score += 10

    return min(score, 100)


def generate_til_angle(commit: dict) -> str:
    """Generate a suggested TIL angle based on commit content."""
    subject = commit["subject"].lower()
    files = commit["files"]

    if "fix" in subject and "ignore" in subject:
        return "Common gotcha - files need special handling"

    if any(".zsh" in f or ".bash" in f for f in files):
        return "Shell configuration tip or optimization"

    if any("docker" in f.lower() for f in files):
        return "Docker/container configuration insight"

    if any(".git" in f for f in files):
        return "Git workflow or configuration tip"

    if "test" in subject:
        return "Testing pattern or debugging approach"

    if "config" in subject or any("config" in f for f in files):
        return "Configuration setup or tooling tip"

    if "performance" in subject or "speed" in subject or "slow" in subject:
        return "Performance optimization technique"

    if subject.startswith("fix"):
        return "Problem-solution pattern worth documenting"
    elif subject.startswith("feat"):
        return "New capability or workflow"
    elif subject.startswith("refactor"):
        return "Code organization or clarity improvement"

    return "Potential learning worth sharing"


def generate_title(commit: dict) -> str:
    """Generate a suggested TIL title from commit."""
    subject = commit["subject"]

    # Remove conventional commit prefixes
    subject = re.sub(r"^(fix|feat|chore|docs|refactor|test|style)(\(.+?\))?:\s*", "", subject)

    # Capitalize first letter
    if subject:
        subject = subject[0].upper() + subject[1:]

    # Truncate if too long
    if len(subject) > 60:
        subject = subject[:57] + "..."

    return subject or "Untitled"


def format_markdown(suggestions: list[dict], days: int, new_count: int, total_count: int) -> str:
    """Format suggestions as markdown output."""
    header = f"📝 TIL Opportunities from Git History (last {days} days):\n"

    if total_count > 0 and new_count == 0:
        return f"""{header}
No new commits to assess ({total_count} commits already reviewed).
"""

    if not suggestions:
        return f"""{header}
No high-potential TIL topics found.

Try:
- Increasing the date range: specify more days
"""

    lines = [header]
    if new_count < total_count:
        lines.append(f"({new_count} new commits assessed, {total_count - new_count} already reviewed)\n")

    for i, commit in enumerate(suggestions, 1):
        files_str = ", ".join(commit["files"][:3]) if commit["files"] else "(files not available)"
        if len(commit["files"]) > 3:
            files_str += f" (+{len(commit['files']) - 3} more)"

        lines.append(f"{i}. **{commit['suggested_title']}**")
        lines.append(f"   - Repo: {commit['repo']}")
        lines.append(f"   - Commit: {commit['hash']} \"{commit['subject'][:50]}{'...' if len(commit['subject']) > 50 else ''}\"")
        lines.append(f"   - Date: {commit['date']}")
        if commit["files"]:
            lines.append(f"   - Files: {files_str}")
        lines.append(f"   - TIL angle: {commit['til_angle']}")
        lines.append("")

    return "\n".join(lines)


def main():
    # Parse arguments
    days = 30
    assessed_hashes = set()

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--assessed-hashes" and i + 1 < len(args):
            assessed_hashes = set(args[i + 1].split(",")) if args[i + 1] else set()
            i += 2
        else:
            try:
                days = int(args[i])
            except ValueError:
                pass
            i += 1

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

    # Filter out already assessed commits
    new_commits = [c for c in commits if c["full_hash"] not in assessed_hashes]
    new_count = len(new_commits)

    # Score and filter new commits
    scored_commits = []
    for commit in new_commits:
        score = score_commit(commit)
        if score >= 25:  # Minimum threshold
            commit["score"] = score
            commit["til_angle"] = generate_til_angle(commit)
            commit["suggested_title"] = generate_title(commit)
            scored_commits.append(commit)

    # Sort by score
    scored_commits.sort(key=lambda c: c["score"], reverse=True)

    # Take top 10
    top_suggestions = scored_commits[:10]

    # Prepare output
    output = {
        "markdown": format_markdown(top_suggestions, days, new_count, total_count),
        "new_commits": [
            {
                "hash": c["full_hash"],
                "message": c["subject"],
                "repo": c["repo"]
            }
            for c in new_commits
        ]
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
