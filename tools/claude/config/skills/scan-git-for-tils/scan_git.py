#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["notion-client"]
# ///
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
    - uv (for dependency management)
"""

import sys
import json

from git.commits import get_github_username, get_commits
from git.formatting import should_skip_commit, format_markdown
from notion.client import get_assessed_commits_from_notion


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
