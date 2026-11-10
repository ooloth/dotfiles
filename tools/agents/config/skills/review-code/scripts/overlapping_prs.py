#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""List the other open PRs that change a file this PR changes.

Another open PR may already fix what a review would flag in this one, or conflict with it on a
shared file when either merges. This reads every open PR in the repository, drafts and PRs against
other base branches included, and reports each one that shares a file with this PR. A rename counts
under both its old and its new path, on either side.

Usage:
  overlapping_prs.py <pr-number> --repo OWNER/NAME

Exit codes:
  0  no other open PR changes a file this PR changes
  1  at least one does; each is listed with the files it shares
  2  the check could not be made, or GitHub's answer was cut short; stderr says why. Never read
     this as 0.

Open PRs and their first 100 files each come from a paged GraphQL listing, and a second GraphQL
query pages through the rest of any PR with more. GraphQL gives a renamed file's new path only, so
this PR's files, and those of any open PR that renames a file, come from REST, which also gives the
old path. This PR is skipped in the listing. Every list, the listing included, is compared with the
count GitHub reports for it, so a short read is never reported as no overlap.
"""

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from typing import Any, NewType, NoReturn

FilePath = NewType("FilePath", str)
PrNumber = NewType("PrNumber", int)

# Upper bounds on the paging loops. Past them the answer would be partial, so the check refuses.
MAX_PR_PAGES = 100  # 50 open PRs a page
MAX_FILE_PAGES = 30  # 100 files a page; GitHub lists at most 3000 files for a PR

OPEN_PRS_QUERY = """
query($owner: String!, $name: String!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: 50, after: $cursor) {
      totalCount
      pageInfo { hasNextPage endCursor }
      nodes {
        number title isDraft baseRefName
        author { login }
        files(first: 100) {
          totalCount
          pageInfo { hasNextPage endCursor }
          nodes { path changeType }
        }
      }
    }
  }
}
"""

PR_FILES_QUERY = """
query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      files(first: 100, after: $cursor) {
        totalCount
        pageInfo { hasNextPage endCursor }
        nodes { path changeType }
      }
    }
  }
}
"""


def cannot_check(message: str) -> NoReturn:
    print(f"overlapping_prs: {message}", file=sys.stderr)
    raise SystemExit(2)


def gh_json(args: list[str]) -> Any:
    try:
        result = subprocess.run(["gh", *args], check=False, capture_output=True, text=True)
    except FileNotFoundError:
        cannot_check("gh is not installed or not on PATH.")
    if result.returncode != 0:
        shown = [a if not a.startswith("query=") else "query=…" for a in args]
        cannot_check(f"`gh {' '.join(shown)}` failed: {result.stderr.strip()}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        cannot_check(f"`gh {args[0]} {args[1]}` did not return JSON: {e}")


@dataclass(frozen=True)
class TargetPr:
    number: PrNumber
    base: str
    paths: frozenset[FilePath]


@dataclass(frozen=True)
class OpenPr:
    number: PrNumber
    title: str
    author: str
    is_draft: bool
    base: str
    paths: frozenset[FilePath]


@dataclass(frozen=True)
class Overlap:
    pr: OpenPr
    shared: frozenset[FilePath]


def rest_paths(repo: str, number: int, expected: int) -> frozenset[FilePath]:
    """Every path a PR touches, a rename's old path included, read from REST."""
    paths: set[FilePath] = set()
    seen = 0
    for page in range(1, MAX_FILE_PAGES + 1):
        if seen == expected:
            break
        files = gh_json(["api", f"repos/{repo}/pulls/{number}/files?per_page=100&page={page}"])
        if not isinstance(files, list):
            cannot_check(f"GitHub's file list for #{number} was not a list.")
        for f in files:
            paths.add(FilePath(f["filename"]))
            if f.get("previous_filename"):
                paths.add(FilePath(f["previous_filename"]))
        seen += len(files)
        if len(files) < 100:
            break
    else:
        if seen != expected:
            cannot_check(f"#{number} has more than {MAX_FILE_PAGES * 100} files to page through.")
    if seen != expected:
        cannot_check(f"GitHub listed {seen} files for #{number} but says it changes {expected}.")
    return frozenset(paths)


def fetch_target(repo: str, number: int) -> TargetPr:
    pr = gh_json(["api", f"repos/{repo}/pulls/{number}"])
    return TargetPr(
        number=PrNumber(pr["number"]),
        base=pr["base"]["ref"],
        paths=rest_paths(repo, number, pr["changed_files"]),
    )


def graphql(query: str, variables: dict[str, str | int | None]) -> Any:
    args = ["api", "graphql", "-f", f"query={query}"]
    for key, value in variables.items():
        if value is None:
            continue
        flag = "-F" if isinstance(value, int) else "-f"
        args += [flag, f"{key}={value}"]
    data = gh_json(args)
    if data.get("errors"):
        cannot_check(f"GitHub's GraphQL API returned errors: {data['errors']}")
    return data["data"]["repository"]


def graphql_paths(owner: str, name: str, number: int, first_page: dict[str, Any]) -> list[Any]:
    """Every file node of an open PR, following the files connection past its first page."""
    page, nodes, pages = first_page, list(first_page["nodes"]), 1
    while page["pageInfo"]["hasNextPage"]:
        if pages == MAX_FILE_PAGES:
            cannot_check(f"#{number} has more than {MAX_FILE_PAGES * 100} files to page through.")
        pages += 1
        variables = {"owner": owner, "name": name, "number": number}
        repo_data = graphql(PR_FILES_QUERY, {**variables, "cursor": page["pageInfo"]["endCursor"]})
        page = repo_data["pullRequest"]["files"]
        nodes += page["nodes"]
    if len(nodes) != first_page["totalCount"]:
        cannot_check(
            f"GitHub listed {len(nodes)} files for #{number} "
            f"but says it changes {first_page['totalCount']}."
        )
    return nodes


def fetch_open_prs(repo: str, skip: PrNumber) -> list[OpenPr]:
    """Every open PR but `skip`, with the paths each one touches."""
    owner, name = repo.split("/", 1)
    prs: list[OpenPr] = []
    listed = 0
    cursor: str | None = None
    for _ in range(MAX_PR_PAGES):
        page = graphql(OPEN_PRS_QUERY, {"owner": owner, "name": name, "cursor": cursor})
        connection = page["pullRequests"]
        listed += len(connection["nodes"])
        for node in connection["nodes"]:
            number = node["number"]
            if number == skip:
                continue
            files = graphql_paths(owner, name, number, node["files"])
            if any(f["changeType"] == "RENAMED" for f in files):
                paths = rest_paths(repo, number, len(files))
            else:
                paths = frozenset(FilePath(f["path"]) for f in files)
            prs.append(
                OpenPr(
                    number=PrNumber(number),
                    title=node["title"],
                    author=(node.get("author") or {}).get("login", "ghost"),
                    is_draft=node["isDraft"],
                    base=node["baseRefName"],
                    paths=paths,
                )
            )
        if not connection["pageInfo"]["hasNextPage"]:
            if listed != connection["totalCount"]:
                cannot_check(
                    f"GitHub listed {listed} open PRs but says there are "
                    f"{connection['totalCount']}. A PR may have opened or closed while reading."
                )
            return prs
        cursor = connection["pageInfo"]["endCursor"]
    cannot_check(f"{repo} has more than {MAX_PR_PAGES * 50} open PRs to page through.")


def find_overlaps(target: TargetPr, others: list[OpenPr]) -> list[Overlap]:
    overlaps = [
        Overlap(pr=pr, shared=target.paths & pr.paths)
        for pr in others
        if pr.number != target.number and target.paths & pr.paths
    ]
    assert all(o.pr.number != target.number for o in overlaps), "target listed as its own overlap"
    assert all(o.shared for o in overlaps), "an overlap with no shared file"
    return overlaps


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pr", type=int)
    parser.add_argument("--repo", required=True)
    args = parser.parse_args()
    if "/" not in args.repo:
        cannot_check(f"--repo must be OWNER/NAME, not {args.repo!r}.")

    target = fetch_target(args.repo, args.pr)
    others = fetch_open_prs(args.repo, target.number)
    overlaps = find_overlaps(target, others)

    noun = "PR" if len(others) == 1 else "PRs"
    print(
        f"PR #{target.number} (base {target.base}) changes {len(target.paths)} paths. "
        f"Checked {len(others)} other open {noun}."
    )
    print()
    if not overlaps:
        print("None of them changes a file this PR changes.")
        raise SystemExit(0)
    for o in sorted(overlaps, key=lambda o: o.pr.number):
        draft = ", draft" if o.pr.is_draft else ""
        print(f"#{o.pr.number} {o.pr.title} ({o.pr.author}{draft}, base {o.pr.base})")
        for path in sorted(o.shared):
            print(f"    {path}")
    raise SystemExit(1)


if __name__ == "__main__":
    main()
