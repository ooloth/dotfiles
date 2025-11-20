#!/usr/bin/env python3
"""
Scan git history for TIL-worthy commits.

Usage:
    python3 scan_git.py [days] [repo_path]

Arguments:
    days: Number of days to look back (default: 30)
    repo_path: Path to git repo (default: current directory)
"""

import subprocess
import sys
import re
from datetime import datetime, timedelta
from collections import defaultdict


def get_git_user_email(repo_path: str) -> str:
    """Get the current git user's email."""
    result = subprocess.run(
        ["git", "-C", repo_path, "config", "user.email"],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def get_commits(repo_path: str, days: int, user_email: str) -> list[dict]:
    """Fetch git commits from the last N days."""
    since_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

    # Format: hash|subject|body|date|files
    log_format = "%H|%s|%b|%ar|"

    result = subprocess.run(
        [
            "git", "-C", repo_path, "log",
            f"--since={since_date}",
            f"--author={user_email}",
            "--no-merges",
            f"--format={log_format}",
            "--name-only",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        return []

    commits = []
    current_commit = None

    for line in result.stdout.split("\n"):
        if "|" in line and line.count("|") >= 4:
            # New commit line
            if current_commit:
                commits.append(current_commit)

            parts = line.split("|")
            current_commit = {
                "hash": parts[0][:7],
                "subject": parts[1],
                "body": parts[2],
                "date": parts[3],
                "files": [],
            }
        elif line.strip() and current_commit:
            # File name line
            current_commit["files"].append(line.strip())

    if current_commit:
        commits.append(current_commit)

    return commits


def score_commit(commit: dict) -> int:
    """Score a commit's TIL potential (0-100)."""
    score = 0
    subject = commit["subject"].lower()
    body = commit["body"].lower()
    files = commit["files"]

    # Skip dependency bot commits
    if "dependabot" in subject or "bump" in subject and "from" in subject:
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
    if len(full_message) > 100 or "\n" in commit["body"]:
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

    # Common patterns
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

    # Default based on commit type
    if subject.startswith("fix"):
        return "Problem-solution pattern worth documenting"
    elif subject.startswith("feat"):
        return "New capability or workflow"
    elif subject.startswith("refactor"):
        return "Code organization or clarity improvement"

    return "Potential learning worth sharing"


def group_related_commits(commits: list[dict]) -> list[dict]:
    """Group commits that touch similar files."""
    # For now, just return scored commits without grouping
    # Future enhancement: cluster by file overlap
    return commits


def format_output(suggestions: list[dict], days: int) -> str:
    """Format suggestions as markdown output."""
    if not suggestions:
        return f"""📝 TIL Opportunities from Git History (last {days} days):

No high-potential TIL topics found.

Try:
- Increasing the date range: `python3 scan_git.py 60`
- Checking a different repository
- Looking at specific branches
"""

    lines = [f"📝 TIL Opportunities from Git History (last {days} days):\n"]

    for i, commit in enumerate(suggestions, 1):
        files_str = ", ".join(commit["files"][:3])
        if len(commit["files"]) > 3:
            files_str += f" (+{len(commit['files']) - 3} more)"

        lines.append(f"{i}. **{commit['suggested_title']}**")
        lines.append(f"   - Commit: {commit['hash']} \"{commit['subject']}\"")
        lines.append(f"   - Date: {commit['date']}")
        lines.append(f"   - Files: {files_str}")
        lines.append(f"   - TIL angle: {commit['til_angle']}")
        lines.append("")

    return "\n".join(lines)


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


def main():
    # Parse arguments
    days = 30
    repo_path = "."

    if len(sys.argv) > 1:
        try:
            days = int(sys.argv[1])
        except ValueError:
            repo_path = sys.argv[1]

    if len(sys.argv) > 2:
        repo_path = sys.argv[2]

    # Get user email
    user_email = get_git_user_email(repo_path)
    if not user_email:
        print("Error: Could not determine git user email")
        sys.exit(1)

    # Get commits
    commits = get_commits(repo_path, days, user_email)
    if not commits:
        print(format_output([], days))
        sys.exit(0)

    # Score and filter commits
    scored_commits = []
    for commit in commits:
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

    # Format and print output
    print(format_output(top_suggestions, days))


if __name__ == "__main__":
    main()
