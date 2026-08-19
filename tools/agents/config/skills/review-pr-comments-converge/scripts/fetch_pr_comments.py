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

Usage: fetch_pr_comments.py <pr-number>
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


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: fetch_pr_comments.py <pr-number>", file=sys.stderr)
        sys.exit(1)

    pr_number = int(sys.argv[1])
    repo_raw = run(["gh", "repo", "view", "--json", "nameWithOwner"])
    name_with_owner = json.loads(repo_raw)["nameWithOwner"]
    owner, name = name_with_owner.split("/", 1)

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
