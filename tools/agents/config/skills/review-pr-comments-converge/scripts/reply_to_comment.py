#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Reply to a PR inline review comment, and optionally resolve its thread.

The comment_id and thread_id are shown by fetch_pr_comments.py. Pass the comment_id here;
the thread_id is looked up automatically when --resolve is used.

Usage:
  reply_to_comment.py <pr-number> <comment-id> <body> [--resolve] [--repo OWNER/NAME]

Arguments:
  pr-number   PR number (integer)
  comment-id  The comment_id from fetch_pr_comments.py output
  body        Reply text (quote in shell if it contains spaces)
  --resolve   Also resolve the review thread after posting the reply
  --repo      Target repository. Without it the repo is inferred from $GH_REPO or the shell's
              working directory — so running this from a different checkout (including this
              skill's own directory) posts to *that* repo's PR of the same number. PR numbers
              are small and collide across repos, so the wrong target is a plausible repo with
              a plausible PR, not an error. Pass --repo whenever the cwd is not the target.
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


def take_option(args: list[str], flag: str) -> tuple[list[str], str | None]:
    """Pull `--flag value` or `--flag=value` out of args. Positional order is preserved.

    Hand-rolled rather than argparse because the reply body is a positional that may begin with
    a dash, which argparse would read as an unknown option.
    """
    for i, arg in enumerate(args):
        if arg == flag:
            if i + 1 >= len(args):
                raise SystemExit(f"error: {flag} needs a value")
            return args[:i] + args[i + 2 :], args[i + 1]
        if arg.startswith(f"{flag}="):
            return args[:i] + args[i + 1 :], arg.split("=", 1)[1]
    return args, None


def get_repo(explicit: str | None) -> tuple[str, str, str]:
    """Resolve the target repo. An explicit --repo wins; otherwise gh infers it from $GH_REPO,
    then from the working directory."""
    if explicit:
        nwo = explicit
    else:
        raw = run(["gh", "repo", "view", "--json", "nameWithOwner"])
        nwo = json.loads(raw)["nameWithOwner"]

    if nwo.count("/") != 1 or not all(nwo.split("/")):
        raise SystemExit(f"error: repo must be OWNER/NAME, got {nwo!r}")

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
    args, repo_arg = take_option(args, "--repo")

    if len(args) < 3:
        print(
            "Usage: reply_to_comment.py <pr-number> <comment-id> <body> [--resolve] [--repo OWNER/NAME]",
            file=sys.stderr,
        )
        sys.exit(1)

    pr_number = int(args[0])
    comment_id = int(args[1])
    body = args[2]

    nwo, owner, name = get_repo(repo_arg)

    # Named before the write, not after. Without --repo the target comes from the working
    # directory, and a wrong cwd yields a real repo with a real PR of the same number rather
    # than an error — so the only thing that catches it is seeing the target first.
    print(f"Target: {nwo}#{pr_number}, comment {comment_id}")

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
