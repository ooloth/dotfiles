#!/usr/bin/env python3
"""Post a GitHub PR review with optional inline comments.

Usage:
    python3 post_review.py <pr-number> <APPROVE|REQUEST_CHANGES|COMMENT> <body> [file:line:body ...]

Each inline comment argument uses the format "file:line:body" where body may contain colons.
"""

import json
import subprocess
import sys


def run(cmd, **kwargs):
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


def get_repo():
    result = run(["gh", "repo", "view", "--json", "owner,name"], check=True)
    data = json.loads(result.stdout)
    return data["owner"]["login"], data["name"]


def parse_comment(arg):
    parts = arg.split(":", 2)
    if len(parts) != 3:
        sys.exit(f"Invalid comment format (expected file:line:body): {arg!r}")
    path, line_str, body = parts
    try:
        line = int(line_str)
    except ValueError:
        sys.exit(f"Invalid line number in: {arg!r}")
    return {"path": path, "line": line, "body": body}


def main():
    if len(sys.argv) < 4:
        sys.exit("Usage: post_review.py <pr-number> <APPROVE|REQUEST_CHANGES|COMMENT> <body> [file:line:body ...]")

    pr_number, event, body = sys.argv[1], sys.argv[2], sys.argv[3]
    comments = [parse_comment(a) for a in sys.argv[4:]]

    valid_events = {"APPROVE", "REQUEST_CHANGES", "COMMENT"}
    if event not in valid_events:
        sys.exit(f"Event must be one of: {', '.join(sorted(valid_events))}")

    owner, repo = get_repo()
    payload = {"body": body, "event": event, "comments": comments}

    result = run(
        ["gh", "api", f"repos/{owner}/{repo}/pulls/{pr_number}/reviews",
         "--method", "POST", "--input", "-"],
        input=json.dumps(payload),
    )

    if result.returncode != 0:
        sys.exit(f"GitHub API error:\n{result.stderr}")

    n = len(comments)
    inline = f" with {n} inline comment{'s' if n != 1 else ''}" if n else ""
    print(f"Review posted ({event}){inline}.")


if __name__ == "__main__":
    main()
