#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Fetch all PR review comments and print them in a structured format for agent consumption.

Output mirrors the GitHub UI: each review is one block — overview body first, then its inline
comments beneath. Reviews with no body show inline comments only.

Each inline comment shows:
  - comment_id  : used by reply_to_comment.py to post a reply
  - thread_id   : used by reply_to_comment.py --resolve to close the conversation

Usage: fetch_pr_comments.py <pr-number> [--repo OWNER/NAME]

Without --repo the repo is inferred from $GH_REPO or the shell's working directory. Pass it
whenever the cwd is not the target — PR numbers collide across repos, so the wrong cwd reads a
different repo's PR rather than failing.
"""

import json
import subprocess
import sys

QUERY = """
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 100) {
            nodes {
              databaseId
              author { login }
              path
              line
              originalLine
              diffHunk
              body
              pullRequestReview { databaseId }
            }
          }
        }
      }
      reviews(first: 100) {
        nodes {
          databaseId
          author { login }
          state
          body
        }
      }
    }
  }
}
"""

HEAVY = "#" * 80
MEDIUM = "─" * 80


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout.strip()


def split_suggestion(body: str) -> tuple[str, str]:
    """Return (body_without_suggestion, suggestion_block) or (body, '')."""
    if "```suggestion" not in body:
        return body, ""
    start = body.index("```suggestion")
    end = body.index("```", start + 13) + 3
    return (body[:start] + body[end:]).strip(), body[start:end]


def indent(text: str, prefix: str = "  ") -> str:
    return "\n".join(prefix + line for line in text.splitlines())


def take_option(args: list[str], flag: str) -> tuple[list[str], str | None]:
    """Pull `--flag value` or `--flag=value` out of args, preserving positional order."""
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


def main() -> None:
    args, repo_arg = take_option(sys.argv[1:], "--repo")

    if not args:
        print("Usage: fetch_pr_comments.py <pr-number> [--repo OWNER/NAME]", file=sys.stderr)
        sys.exit(1)

    pr_number = int(args[0])
    name_with_owner, owner, name = get_repo(repo_arg)

    # Printed so the reply step can be checked against the same target these ids came from.
    print(f"# Source: {name_with_owner}#{pr_number}")
    print()

    raw = run([
        "gh", "api", "graphql",
        "-f", f"query={QUERY}",
        "-F", f"owner={owner}",
        "-F", f"name={name}",
        "-F", f"number={pr_number}",
    ])
    data = json.loads(raw)["data"]["repository"]["pullRequest"]
    threads = data["reviewThreads"]["nodes"]
    reviews = data["reviews"]["nodes"]

    threads_by_review: dict[int, list[tuple[dict, list[dict]]]] = {}
    orphan_threads: list[tuple[dict, list[dict]]] = []
    for thread in threads:
        comments = thread["comments"]["nodes"]
        first_comment = comments[0]
        review_ref = first_comment.get("pullRequestReview")
        if review_ref:
            rid = review_ref["databaseId"]
            threads_by_review.setdefault(rid, []).append((thread, comments))
        else:
            orphan_threads.append((thread, comments))

    comment_idx = 1
    for review in [r for r in reviews if r.get("body", "").strip() or threads_by_review.get(r["databaseId"])]:
        rid = review["databaseId"]
        author = review["author"]["login"]
        state = review["state"]
        body = review.get("body", "").strip()
        review_threads = threads_by_review.get(rid, [])
        n = len(review_threads)

        print(HEAVY)
        print(f"# REVIEW by {author} ({state})  [review_id: {rid}]")
        print(HEAVY)

        if body:
            print()
            print("OVERVIEW:")
            print(indent(body))

        if review_threads:
            for i, (thread, comments) in enumerate(review_threads):
                print()
                print(MEDIUM)
                first = comments[0]
                line = first.get("line") or first.get("originalLine") or "?"
                comment_body, suggestion = split_suggestion(first["body"])

                print(f"COMMENT [{comment_idx} of {n}]  {first['path']}:{line}")
                print(f"  comment_id : {first['databaseId']}")
                print(f"  thread_id  : {thread['id']}  (resolved: {'yes' if thread['isResolved'] else 'no'})")
                print()
                print("  DIFF HUNK:")
                print(indent(first["diffHunk"], "    "))
                print()
                print("  BODY:")
                print(indent(comment_body, "    "))
                if suggestion:
                    print()
                    print("  SUGGESTION:")
                    print(indent(suggestion, "    "))
                if len(comments) > 1:
                    print()
                    print("  REPLIES:")
                    for reply in comments[1:]:
                        print(f"    {reply['author']['login']}: {reply['body'].strip()}")
                comment_idx += 1

        print()
        print(HEAVY)
        print()

    # Orphaned threads (no parent review — rare but possible).
    if orphan_threads:
        print(HEAVY)
        print("# ORPHANED COMMENTS (no parent review)")
        print(HEAVY)
        for thread, comments in orphan_threads:
            print()
            print(MEDIUM)
            first = comments[0]
            line = first.get("line") or first.get("originalLine") or "?"
            comment_body, suggestion = split_suggestion(first["body"])

            print(f"COMMENT [{comment_idx}]  {first['author']['login']} @ {first['path']}:{line}")
            print(f"  comment_id : {first['databaseId']}")
            print(f"  thread_id  : {thread['id']}  (resolved: {'yes' if thread['isResolved'] else 'no'})")
            print()
            print("  DIFF HUNK:")
            print(indent(first["diffHunk"], "    "))
            print()
            print("  BODY:")
            print(indent(comment_body, "    "))
            if suggestion:
                print()
                print("  SUGGESTION:")
                print(indent(suggestion, "    "))
            if len(comments) > 1:
                print()
                print("  REPLIES:")
                for reply in comments[1:]:
                    print(f"    {reply['author']['login']}: {reply['body'].strip()}")
            comment_idx += 1

        print()
        print(HEAVY)
        print()


if __name__ == "__main__":
    main()
