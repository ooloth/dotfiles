#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Post a GitHub PR review, with optional inline comments, from a JSON file.

The review is read from a file rather than from shell arguments so that backticks, $(...) and
quotes in the text reach GitHub exactly as written. Write the file with an editor or the Write
tool, never a shell heredoc.

Usage:
  post_review.py <pr-number> <review.json> --repo OWNER/NAME [--dry-run]

Review file:
  {
    "event": "APPROVE" | "REQUEST_CHANGES" | "COMMENT",
    "body": "Overall summary (may be empty only for APPROVE)",
    "commit_id": "<head SHA the review was made against>",      (optional)
    "comments": [                                                (optional)
      {"path": "src/app.py", "line": 42, "side": "RIGHT", "body": "..."}
    ]
  }

  line is the line number in the file (not a diff position). side is RIGHT (the PR's version,
  the default) or LEFT (the base version, for deleted lines).

--dry-run validates the file and prints the exact payload that would be sent, without posting.
"""

import argparse
import json
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal, get_args

Event = Literal["APPROVE", "REQUEST_CHANGES", "COMMENT"]
Side = Literal["LEFT", "RIGHT"]
EVENTS: tuple[str, ...] = get_args(Event)
SIDES: tuple[str, ...] = get_args(Side)


@dataclass(frozen=True)
class InlineComment:
    path: str
    line: int
    side: Side
    body: str


@dataclass(frozen=True)
class Review:
    event: Event
    body: str
    commit_id: str | None
    comments: tuple[InlineComment, ...]


def read_review_file(path: Path) -> Any:
    try:
        text = path.read_text()
    except OSError as e:
        raise SystemExit(f"Could not read review file {path}: {e.strerror}.")
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        raise SystemExit(f"Review file {path} is not valid JSON: {e}.")


def require_text(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise SystemExit(f"{field} must be a non-empty string, got {value!r}.")
    return value


def parse_comment(raw: Any, index: int) -> InlineComment:
    field = f"comments[{index}]"
    if not isinstance(raw, dict):
        raise SystemExit(f"{field} must be an object, got {raw!r}.")
    line = raw.get("line")
    # bool is a subclass of int, so True would otherwise pass as line 1.
    if not isinstance(line, int) or isinstance(line, bool) or line < 1:
        raise SystemExit(f"{field}.line must be a positive integer, got {line!r}.")
    side = raw.get("side", "RIGHT")
    if side not in SIDES:
        raise SystemExit(
            f"{field}.side must be one of {', '.join(SIDES)}, got {side!r}."
        )
    return InlineComment(
        path=require_text(raw.get("path"), f"{field}.path"),
        line=line,
        side=side,
        body=require_text(raw.get("body"), f"{field}.body"),
    )


def parse_review(raw: Any) -> Review:
    if not isinstance(raw, dict):
        raise SystemExit(
            f"The review file must contain a JSON object, got {type(raw).__name__}."
        )
    event = raw.get("event")
    if event not in EVENTS:
        raise SystemExit(f"event must be one of {', '.join(EVENTS)}, got {event!r}.")
    body = raw.get("body", "")
    if not isinstance(body, str):
        raise SystemExit(f"body must be a string, got {body!r}.")
    if event != "APPROVE" and not body:
        raise SystemExit(
            f"A {event} review needs a non-empty body; GitHub rejects it otherwise."
        )
    commit_id = raw.get("commit_id")
    if commit_id is not None:
        commit_id = require_text(commit_id, "commit_id")
    comments = raw.get("comments", [])
    if not isinstance(comments, list):
        raise SystemExit(f"comments must be a list, got {comments!r}.")
    return Review(
        event=event,
        body=body,
        commit_id=commit_id,
        comments=tuple(parse_comment(c, i) for i, c in enumerate(comments)),
    )


def to_api_payload(review: Review) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "event": review.event,
        "body": review.body,
        "comments": [
            {"path": c.path, "line": c.line, "side": c.side, "body": c.body}
            for c in review.comments
        ],
    }
    if review.commit_id is not None:
        payload["commit_id"] = review.commit_id
    return payload


def post(repo: str, pr: int, payload: dict[str, Any]) -> str:
    result = subprocess.run(
        [
            "gh",
            "api",
            f"repos/{repo}/pulls/{pr}/reviews",
            "--method",
            "POST",
            "--input",
            "-",
        ],
        input=json.dumps(payload),
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"GitHub rejected the review; nothing was posted.\n{result.stderr}"
        )
    return json.loads(result.stdout).get("html_url", "")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("pr", type=int, help="PR number")
    parser.add_argument("review_file", type=Path, help="path to the review JSON file")
    parser.add_argument(
        "--repo",
        required=True,
        help="target repository as OWNER/NAME; required so the review cannot land on a PR "
        "with the same number in whatever repo the shell happens to be in",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the payload that would be sent; post nothing",
    )
    args = parser.parse_args()

    payload = to_api_payload(parse_review(read_review_file(args.review_file)))

    if args.dry_run:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return

    url = post(args.repo, args.pr, payload)
    n = len(payload["comments"])
    inline = f" with {n} inline comment{'s' if n != 1 else ''}" if n else ""
    print(f"Review posted ({payload['event']}){inline}: {url}")


if __name__ == "__main__":
    main()
