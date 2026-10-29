#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Fetch all PR review comments and print them in a structured format for agent consumption.

Output mirrors the GitHub UI: each review is one block — overview body first, then its inline
comments beneath. Reviews with no body show inline comments only.

Each review shows the commit it was submitted against and when. Each inline comment shows:
  - comment_id  : used by reply_to_comment.py to post a reply
  - thread_id   : used by reply_to_comment.py --resolve to close the conversation
  - outdated    : whether the code it was left on has changed since

PR conversation comments (the timeline, where some bots post their reviews) follow, oldest first,
each with when it was posted. Reply to these with `gh pr comment`.

Every page of every list is fetched, so nothing is left out. The script exits 1 instead of printing
a partial picture when a thread has more replies than one request returns, when a list runs past
MAX_PAGES, or when gh fails.

Callers: the review-pr-comments-converge skill (replies and resolves threads) and the review-code
skill (reconciles earlier reviews). A change to the output format reaches both.

Usage: fetch_pr_comments.py <pr-number> [--repo OWNER/NAME]

Without --repo the repo is inferred from $GH_REPO or the shell's working directory. Pass it
whenever the cwd is not the target — PR numbers collide across repos, so the wrong cwd reads a
different repo's PR rather than failing.
"""

import json
import subprocess
import sys
from dataclasses import dataclass

# 100 is the most GitHub returns per page, so 50 pages is 5,000 items in one list. A list still
# reporting another page after that is a GitHub fault, and the run stops rather than loop on it.
MAX_PAGES = 50

# Each list is requested only while it has pages left. A finished list answers its last cursor with
# a null endCursor, and sending that back would restart it from the first page.
QUERY = """
query(
  $owner: String!, $name: String!, $number: Int!,
  $withThreads: Boolean!, $threadsAfter: String,
  $withReviews: Boolean!, $reviewsAfter: String,
  $withComments: Boolean!, $commentsAfter: String
) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $threadsAfter) @include(if: $withThreads) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 100) {
            pageInfo { hasNextPage }
            totalCount
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
      reviews(first: 100, after: $reviewsAfter) @include(if: $withReviews) {
        pageInfo { hasNextPage endCursor }
        nodes {
          databaseId
          author { login }
          state
          body
          submittedAt
          commit { oid }
        }
      }
      comments(first: 100, after: $commentsAfter) @include(if: $withComments) {
        pageInfo { hasNextPage endCursor }
        nodes {
          databaseId
          author { login }
          body
          url
          createdAt
        }
      }
    }
  }
}
"""

# (cursor variable prefix, GraphQL field) for each list the query pages.
LISTS = (("threads", "reviewThreads"), ("reviews", "reviews"), ("comments", "comments"))


@dataclass(frozen=True)
class Discussion:
    """Everything said on a PR, every list fetched to its last page."""

    threads: list[dict]
    reviews: list[dict]
    conversation: list[dict]


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


def fetch_page(
    target: str, owner: str, name: str, number: int, cursors: dict[str, str | None]
) -> dict:
    """Request the next page of every list named in `cursors`; a None cursor means its first page."""
    cmd = ["gh", "api", "graphql", "-f", f"query={QUERY}"]
    cmd += ["-F", f"owner={owner}", "-F", f"name={name}", "-F", f"number={number}"]
    for key, _ in LISTS:
        cmd += ["-F", f"with{key.capitalize()}={'true' if key in cursors else 'false'}"]
        if cursors.get(key) is not None:
            cmd += ["-F", f"{key}After={cursors[key]}"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit(f"error: gh could not fetch {target}: {result.stderr.strip()}")
    return json.loads(result.stdout)["data"]["repository"]["pullRequest"]


def fetch_discussion(target: str, owner: str, name: str, number: int) -> Discussion:
    """Page every list to its end. Exits rather than return a picture with anything missing."""
    collected: dict[str, list[dict]] = {key: [] for key, _ in LISTS}
    cursors: dict[str, str | None] = {key: None for key, _ in LISTS}
    for _ in range(MAX_PAGES):
        page = fetch_page(target, owner, name, number, cursors)
        for key, field in LISTS:
            if key not in cursors:
                continue
            connection = page[field]
            collected[key].extend(connection["nodes"])
            if connection["pageInfo"]["hasNextPage"]:
                cursor = connection["pageInfo"]["endCursor"]
                assert cursor is not None, f"{field} reported another page with no cursor"
                assert cursor != cursors[key], f"{field} cursor did not advance from {cursor}"
                cursors[key] = cursor
            else:
                del cursors[key]
        if not cursors:
            break
    else:
        unfinished = ", ".join(field for key, field in LISTS if key in cursors)
        raise SystemExit(f"error: {unfinished} still had more pages after {MAX_PAGES} on {target}")

    for thread in collected["threads"]:
        replies = thread["comments"]
        if replies["pageInfo"]["hasNextPage"]:
            first = replies["nodes"][0]
            line = first.get("line") or first.get("originalLine") or "?"
            raise SystemExit(
                f"error: the thread at {first['path']}:{line} on {target} has "
                f"{replies['totalCount']} replies, and only the first {len(replies['nodes'])} "
                f"were fetched (thread_id {thread['id']})"
            )

    return Discussion(collected["threads"], collected["reviews"], collected["comments"])


def main() -> None:
    args, repo_arg = take_option(sys.argv[1:], "--repo")

    if not args:
        print("Usage: fetch_pr_comments.py <pr-number> [--repo OWNER/NAME]", file=sys.stderr)
        sys.exit(1)

    pr_number = int(args[0])
    name_with_owner, owner, name = get_repo(repo_arg)
    target = f"{name_with_owner}#{pr_number}"
    print_discussion(target, fetch_discussion(target, owner, name, pr_number))


def print_discussion(target: str, discussion: Discussion) -> None:
    threads = discussion.threads
    reviews = discussion.reviews
    conversation = discussion.conversation

    # Printed so the reply step can be checked against the same target these ids came from.
    print(f"# Source: {target}")
    print()

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
    for review in [
        r for r in reviews if r.get("body", "").strip() or threads_by_review.get(r["databaseId"])
    ]:
        rid = review["databaseId"]
        author = review["author"]["login"]
        state = review["state"]
        body = review.get("body", "").strip()
        review_threads = threads_by_review.get(rid, [])
        n = len(review_threads)

        print(HEAVY)
        print(f"# REVIEW by {author} ({state})  [review_id: {rid}]")
        # Commit is null when the reviewed commit no longer exists, e.g. after a force-push.
        commit = (review.get("commit") or {}).get("oid") or "unknown"
        print(f"# commit {commit}  submitted {review.get('submittedAt') or 'unknown'}")
        print(HEAVY)

        if body:
            print()
            print("OVERVIEW:")
            print(indent(body))

        if review_threads:
            for thread, comments in review_threads:
                print()
                print(MEDIUM)
                first = comments[0]
                line = first.get("line") or first.get("originalLine") or "?"
                comment_body, suggestion = split_suggestion(first["body"])

                print(f"COMMENT [{comment_idx} of {n}]  {first['path']}:{line}")
                print(f"  comment_id : {first['databaseId']}")
                print(
                    f"  thread_id  : {thread['id']}  (resolved: {'yes' if thread['isResolved'] else 'no'})"
                )
                print(f"  outdated   : {'yes' if thread['isOutdated'] else 'no'}")
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
            print(
                f"  thread_id  : {thread['id']}  (resolved: {'yes' if thread['isResolved'] else 'no'})"
            )
            print(f"  outdated   : {'yes' if thread['isOutdated'] else 'no'}")
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

    # GitHub returns these oldest first, so a reply always follows what it answers.
    if conversation:
        print(HEAVY)
        print("# PR CONVERSATION COMMENTS (oldest first; reply with gh pr comment)")
        print(HEAVY)
        for comment in conversation:
            print()
            print(MEDIUM)
            author = comment["author"]["login"] if comment.get("author") else "ghost"
            print(f"CONVERSATION COMMENT  {author}")
            print(f"  comment_id : {comment['databaseId']}")
            print(f"  url        : {comment['url']}")
            print(f"  created    : {comment['createdAt']}")
            print()
            print("  BODY:")
            print(indent(comment["body"].strip(), "    "))

        print()
        print(HEAVY)
        print()


if __name__ == "__main__":
    main()
