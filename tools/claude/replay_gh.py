"""gh for a replay: serves one ticket as it stood when planning began, plus the comments this replay
posts, and saves those comments instead of posting them.

`replay.py` copies this file into the replay's `bin/gh`, beside the `gh-snapshot.json` that names the
ticket, its snapshot and the capture folder, and puts the interpreter running `replay.py` in its
first line. It serves nothing else. Every call is logged to `gh-calls.log` in the capture folder, and
every call it does not model is refused, so the audit shows it.
"""

from __future__ import annotations

import datetime
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, NoReturn

CONFIG = Path(__file__).with_name("gh-snapshot.json")
cfg: dict[str, Any] = json.loads(CONFIG.read_text())
args = sys.argv[1:]
capture = Path(cfg["capture"])
url = f"https://github.com/{cfg['repo']}/issues/{cfg['number']}"
owner = {"login": cfg["repo"].split("/")[0]}


def log(served: bool) -> None:
    with (capture / "gh-calls.log").open("a") as f:
        f.write(json.dumps({"args": args, "served": served}) + "\n")


def refuse() -> NoReturn:
    log(False)
    sys.stderr.write("gh: unavailable in replay: " + " ".join(args) + "\n")
    sys.exit(1)


def flags(rest: list[str], takes_value: set[str], switches: set[str]) -> dict[str, str]:
    """The flags in `rest`, by name. Any flag outside the two sets, or one missing its value, is
    refused, because a flag the stand-in ignores would make it answer differently from gh."""
    found: dict[str, str] = {}
    i = 0
    while i < len(rest):
        a = rest[i]
        name, eq, value = a.partition("=")
        if name in takes_value and eq:
            found[name] = value
        elif a in takes_value and i + 1 < len(rest):
            found[a] = rest[i + 1]
            i += 1
        elif a in switches:
            found[a] = ""
        else:
            refuse()
        i += 1
    return found


def first(found: dict[str, str], *names: str) -> str | None:
    return next((found[n] for n in names if n in found), None)


def emit(data: object, query: str | None) -> NoReturn:
    """Print as gh does: JSON, or the result of --jq, which gh prints the way `jq -r` does."""
    log(True)
    if query is None:
        print(json.dumps(data))
        sys.exit(0)
    done = subprocess.run(["jq", "-r", query], input=json.dumps(data), text=True, check=False)
    sys.exit(done.returncode)


def comment_files() -> list[Path]:
    return sorted(capture.glob("comment-*.md"))


def posted() -> list[dict[str, str]]:
    """The comments this replay has posted, oldest first, each with the time it was saved."""
    found = []
    for path in comment_files():
        at = datetime.datetime.fromtimestamp(path.stat().st_mtime, datetime.UTC)
        n = int(path.stem.rsplit("-", 1)[1])
        found.append(
            {
                "body": path.read_text(),
                "createdAt": at.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "url": f"{url}#issuecomment-replay-{n}",
            }
        )
    return found


def is_this_ticket(target: str, repo: str | None) -> bool:
    prefix = "https://github.com/"
    if target.startswith(prefix):
        parts = target[len(prefix) :].split("/")
        if len(parts) != 4 or parts[2] != "issues":
            return False
        return f"{parts[0]}/{parts[1]}" == cfg["repo"] and parts[3] == str(cfg["number"])
    return target.lstrip("#") == str(cfg["number"]) and repo == cfg["repo"]


def view(target: str, rest: list[str]) -> NoReturn:
    found = flags(rest, {"--json", "-q", "--jq", "-R", "--repo"}, {"--comments"})
    if not is_this_ticket(target, first(found, "-R", "--repo")):
        refuse()
    comments = [dict(c, author=owner) for c in posted()]
    fields = found.get("--json")
    if fields is None:
        log(True)
        print(cfg["title"] + "\n\n" + cfg["body"])
        if "--comments" in found:
            for c in comments:
                print(f"\n--\n{owner['login']} • {c['createdAt']}\n\n{c['body']}")
        sys.exit(0)
    ticket = {
        "number": cfg["number"],
        "title": cfg["title"],
        "body": cfg["body"],
        "comments": comments,
        "parent": None,
        "blockedBy": {"nodes": [], "totalCount": 0},
        "blocking": {"nodes": [], "totalCount": 0},
        "subIssues": {"nodes": [], "totalCount": 0},
        "state": "OPEN",
        "labels": [],
        "url": url,
    }
    wanted = fields.split(",")
    if any(f not in ticket for f in wanted):
        refuse()
    emit({f: ticket[f] for f in wanted}, first(found, "-q", "--jq"))


def comment(target: str, rest: list[str]) -> NoReturn:
    found = flags(rest, {"--body-file", "-F", "--body", "-b", "-R", "--repo"}, {"--edit-last"})
    if not is_this_ticket(target, first(found, "-R", "--repo")):
        refuse()
    path = first(found, "--body-file", "-F")
    if path == "-":
        body: str | None = sys.stdin.read()
    elif path is not None:
        body = Path(path).read_text()
    else:
        body = first(found, "--body", "-b")
    if body is None:
        refuse()
    existing = comment_files()
    if "--edit-last" in found:
        # gh edits the caller's last comment in place, so the correction replaces the original.
        if not existing:
            refuse()
        saved = existing[-1]
    else:
        saved = capture / f"comment-{len(existing) + 1:03d}.md"
    saved.write_text(body)
    log(True)
    print(f"{url}#issuecomment-replay-{int(saved.stem.rsplit('-', 1)[1])}")
    sys.exit(0)


def is_write(a: str) -> bool:
    # Short write flags can be joined to their value, as in `-XPOST` or `-fbody=x`.
    long_writes = ("--method", "--field", "--raw-field", "--input")
    return a.startswith(("-X", "-f", "-F")) or a.split("=", 1)[0] in long_writes


def api(rest: list[str]) -> NoReturn:
    """The two read-only endpoints a skill uses to check its own comments, for this ticket only."""
    takes_value = {"-q", "--jq", "-H", "--header", "--cache"}
    endpoints: list[str] = []
    query: str | None = None
    i = 0
    while i < len(rest):
        a = rest[i]
        name, eq, value = a.partition("=")
        if is_write(a):
            refuse()
        elif name in takes_value and eq:
            query = value if name in ("-q", "--jq") else query
        elif a in takes_value and i + 1 < len(rest):
            query = rest[i + 1] if a in ("-q", "--jq") else query
            i += 1
        elif a == "--paginate":
            pass
        elif a.startswith("-"):
            # --template and every other flag the stand-in doesn't model.
            refuse()
        else:
            endpoints.append(a.lstrip("/"))
        i += 1
    base = f"repos/{cfg['repo']}/issues/{cfg['number']}"
    comments = [
        {"body": c["body"], "created_at": c["createdAt"], "user": owner, "html_url": c["url"]}
        for c in posted()
    ]
    if endpoints == [base + "/comments"]:
        emit(comments, query)
    if endpoints == [base]:
        ticket = {
            "number": cfg["number"],
            "title": cfg["title"],
            "body": cfg["body"],
            "state": "open",
            "comments": len(comments),
            "html_url": url,
        }
        emit(ticket, query)
    refuse()


def main() -> NoReturn:
    if args[:2] == ["issue", "view"] and len(args) > 2:
        view(args[2], args[3:])
    if args[:2] == ["issue", "comment"] and len(args) > 2:
        comment(args[2], args[3:])
    if args[:1] == ["api"]:
        api(args[1:])
    refuse()


if __name__ == "__main__":
    main()
