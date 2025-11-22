"""Git commit formatting utilities."""

from __future__ import annotations

from datetime import datetime

from git.types import Commit


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


def should_skip_commit(commit: Commit) -> bool:
    """Check if commit should be filtered out entirely."""
    subject = commit.subject.lower()

    # Skip dependency bot commits
    if "dependabot" in subject or ("bump" in subject and "from" in subject):
        return True

    # Skip merge commits
    if subject.startswith("merge"):
        return True

    return False


def format_markdown(commits: list[Commit], days: int, new_count: int, total_count: int) -> str:
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
        files_str = ", ".join(commit.files[:5]) if commit.files else "(no files)"
        if len(commit.files) > 5:
            files_str += f" (+{len(commit.files) - 5} more)"

        lines.append(f"{i}. [{commit.repo}] {commit.subject}")
        lines.append(f"   Hash: {commit.hash} (index: {i-1}) | Date: {commit.date}")
        if commit.body:
            body_preview = commit.body[:200] + "..." if len(commit.body) > 200 else commit.body
            lines.append(f"   Body: {body_preview}")
        lines.append(f"   Files: {files_str}")
        lines.append(f"   URL: {commit.url}")
        lines.append("")

    return "\n".join(lines)
