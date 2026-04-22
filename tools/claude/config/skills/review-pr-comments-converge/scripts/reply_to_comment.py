#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Reply to a PR inline review comment, and optionally resolve its thread.

The comment_id and thread_id are shown by fetch_pr_comments.py. Pass the comment_id here;
the thread_id is looked up automatically when --resolve is used.

Usage:
  reply_to_comment.py <pr-number> <comment-id> <body> [--resolve]

Arguments:
  pr-number   PR number (integer)
  comment-id  The comment_id from fetch_pr_comments.py output
  body        Reply text (quote in shell if it contains spaces)
  --resolve   Also resolve the review thread after posting the reply
"""

import json
import subprocess
import sys

THREAD_LOOKUP_QUERY = """
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          comments(first: 1) {
            nodes { databaseId }
          }
        }
      }
    }
  }
}
"""

RESOLVE_MUTATION = """
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}
"""


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout.strip()


def get_repo() -> tuple[str, str, str]:
    raw = run(["gh", "repo", "view", "--json", "nameWithOwner"])
    nwo = json.loads(raw)["nameWithOwner"]
    owner, name = nwo.split("/", 1)
    return nwo, owner, name


def find_thread_id(owner: str, name: str, pr_number: int, comment_id: int) -> str:
    raw = run([
        "gh", "api", "graphql",
        "-f", f"query={THREAD_LOOKUP_QUERY}",
        "-F", f"owner={owner}",
        "-F", f"name={name}",
        "-F", f"number={pr_number}",
    ])
    threads = json.loads(raw)["data"]["repository"]["pullRequest"]["reviewThreads"]["nodes"]
    for thread in threads:
        for comment in thread["comments"]["nodes"]:
            if comment["databaseId"] == comment_id:
                return thread["id"]
    raise SystemExit(f"error: no thread found for comment_id {comment_id} on PR {pr_number}")


def main() -> None:
    args = sys.argv[1:]
    resolve = "--resolve" in args
    args = [a for a in args if a != "--resolve"]

    if len(args) < 3:
        print(
            "Usage: reply_to_comment.py <pr-number> <comment-id> <body> [--resolve]",
            file=sys.stderr,
        )
        sys.exit(1)

    pr_number = int(args[0])
    comment_id = int(args[1])
    body = args[2]

    nwo, owner, name = get_repo()

    run([
        "gh", "api",
        f"repos/{nwo}/pulls/{pr_number}/comments/{comment_id}/replies",
        "-X", "POST",
        "-f", f"body={body}",
    ])
    print(f"Replied to comment {comment_id}.")

    if resolve:
        thread_id = find_thread_id(owner, name, pr_number, comment_id)
        run([
            "gh", "api", "graphql",
            "-f", f"query={RESOLVE_MUTATION}",
            "-F", f"threadId={thread_id}",
        ])
        print(f"Resolved thread {thread_id}.")


if __name__ == "__main__":
    main()
