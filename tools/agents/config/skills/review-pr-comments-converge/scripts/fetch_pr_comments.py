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
each with when it was posted and when it was last edited, or `no`. A bot such as rex-rx-agent posts
a placeholder and later edits its whole review into it, so an unchanged created time does not mean
nothing new was said. Reply to these with `gh pr comment`.

Each review and conversation comment also shows `thank`, the line a reply to it opens with. A person
is tagged by login. A bot is thanked by its name in BOT_NAMES and never tagged, because mentioning a
review bot asks it to review again. Beside it, `refer_as` is how prose such as a review body names
that author, on the same rule: `@login` for a person, the BOT_NAMES name for a bot, and
`a deleted account` for a deleted one. A bot missing from BOT_NAMES, or an author of a kind this
script does not know, shows `UNKNOWN` in both so the caller asks rather than guesses.

Each review with a body, each inline thread and each conversation comment also shows `answered`,
whether it has been answered already, judged from the PR as it stands. A resolved thread counts as
answered whoever resolved it. For replies and top-level answers, an answerer is the PR's author or
the gh login running this script, listed on the `# Answerers:` line under `# Source:`; a deleted
account never is one.
  - `yes (...)` names the evidence: the thread was resolved, an answerer's reply is the thread's
    newest comment and nothing in it changed at or after that reply, or for a review body or
    conversation comment, an answerer posted a conversation comment, or a review with a body, after
    it was posted or last edited. A same-second tie counts as new feedback.
  - `no` means nothing answered it yet.
  - `n/a (yours)` marks an item only answerers wrote.
Pending (unsubmitted) posts never answer anything, and neither does the empty review GitHub creates
for an inline reply.

Every page of every list is fetched, so nothing is left out. The script exits 1 instead of printing
a partial picture when a thread has more replies than one request returns, when a list runs past
MAX_PAGES, when gh fails, or when a time, a comment's state or the gh login cannot be read, since
then no item could be judged.

Callers: the review-pr-comments-converge skill (replies and resolves threads) and the review-code
skill (reconciles earlier reviews). A change to the output format reaches both. The monitor-prs
skill also reads BOT_NAMES as its list of review bots.

Usage: fetch_pr_comments.py <pr-number> [--repo OWNER/NAME]

Without --repo the repo is inferred from $GH_REPO or the shell's working directory. Pass it
whenever the cwd is not the target — PR numbers collide across repos, so the wrong cwd reads a
different repo's PR rather than failing.
"""

import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Literal, NewType, assert_never

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
  viewer { login }
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      author { login __typename }
      reviewThreads(first: 100, after: $threadsAfter) @include(if: $withThreads) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          resolvedBy { login __typename }
          isOutdated
          comments(first: 100) {
            pageInfo { hasNextPage }
            totalCount
            nodes {
              databaseId
              author { login __typename }
              state
              createdAt
              lastEditedAt
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
          author { login __typename }
          state
          body
          submittedAt
          createdAt
          lastEditedAt
          commit { oid }
        }
      }
      comments(first: 100, after: $commentsAfter) @include(if: $withComments) {
        pageInfo { hasNextPage endCursor }
        nodes {
          databaseId
          author { login __typename }
          body
          url
          createdAt
          lastEditedAt
        }
      }
    }
  }
}
"""

# (cursor variable prefix, GraphQL field) for each list the query pages.
LISTS = (("threads", "reviewThreads"), ("reviews", "reviews"), ("comments", "comments"))


# The name each review bot is thanked by. A bot is never @-mentioned: rex-rx starts a new review
# whenever its handle is mentioned on a PR. monitor-prs also reads these keys as its list of review
# bots, so a top-level comment from any bot listed here counts there as feedback to prepare.
BOT_NAMES = {"rex-rx-agent": "Rex", "copilot-pull-request-reviewer": "Copilot"}


@dataclass(frozen=True)
class Person:
    login: str


@dataclass(frozen=True)
class Bot:
    login: str


@dataclass(frozen=True)
class Ghost:
    """An author whose account was deleted. GitHub returns no author at all."""


@dataclass(frozen=True)
class UnrecognisedActor:
    kind: str
    login: str


Reviewer = Person | Bot | Ghost | UnrecognisedActor


def parse_reviewer(author: dict | None) -> Reviewer:
    if author is None:
        return Ghost()
    match author.get("__typename"):
        case "User":
            return Person(author["login"])
        case "Bot":
            return Bot(author["login"])
        case kind:
            return UnrecognisedActor(str(kind), author["login"])


def login_of(reviewer: Reviewer) -> str:
    match reviewer:
        case Ghost():
            return "ghost"
        case Person(login) | Bot(login) | UnrecognisedActor(_, login):
            return login


def refer_as(reviewer: Reviewer) -> str:
    """How prose names this reviewer: a person is tagged so they are notified, a bot is not."""
    match reviewer:
        case Person(login):
            return f"@{login}"
        case Bot(login) if login in BOT_NAMES:
            return BOT_NAMES[login]
        case Bot(login):
            return f"UNKNOWN (bot {login})"
        case Ghost():
            return "a deleted account"
        case UnrecognisedActor(kind, login):
            return f"UNKNOWN ({kind} {login})"


def thank_line(reviewer: Reviewer) -> str:
    name = refer_as(reviewer)
    match reviewer:
        case Person():
            return f"{name} Thanks for the feedback:"
        case Bot(login) if login in BOT_NAMES:
            return f"Thanks for the feedback, {name}:"
        case Ghost():
            return "Thanks for the feedback:"
        case Bot() | UnrecognisedActor():
            return name


@dataclass(frozen=True)
class Answerers:
    """The accounts whose posts answer feedback: the PR's author and the gh login running this."""

    pr_author: Reviewer
    viewer: str

    def includes(self, reviewer: Reviewer) -> bool:
        """Matched on the Reviewer variant, so a deleted account never answers, even when the PR
        author's account is the one deleted, and a real account named `ghost` is not mistaken for
        it."""
        match reviewer:
            case Ghost():
                return False
            case Person(login) if login == self.viewer:
                return True
            case Person() | Bot() | UnrecognisedActor():
                return reviewer == self.pr_author
            case _:
                assert_never(reviewer)

    def describe(self) -> str:
        viewer = f"{self.viewer} (gh login)"
        match self.pr_author:
            case Ghost():
                return f"{viewer}; the PR author's account was deleted"
            case Person(login) if login == self.viewer:
                return f"{login} (PR author and gh login)"
            case Person() | Bot() | UnrecognisedActor():
                return f"{login_of(self.pr_author)} (PR author), {viewer}"
            case _:
                assert_never(self.pr_author)


@dataclass(frozen=True)
class Discussion:
    """Everything said on a PR, every list fetched to its last page."""

    threads: list[dict]
    reviews: list[dict]
    conversation: list[dict]
    answerers: Answerers


PostId = NewType("PostId", int)


@dataclass(frozen=True)
class Post:
    """A comment or review that went public. `changed_at` is its latest created, submitted or edited
    time, so it is never before `posted_at`."""

    id: PostId
    author: Reviewer
    posted_at: datetime
    changed_at: datetime


@dataclass(frozen=True)
class NotPosted:
    """A pending thread comment, or a review not submitted. It can never answer anything."""

    author: Reviewer


@dataclass(frozen=True)
class Unreadable:
    """Values GitHub returned that this script cannot judge, each named in a sentence."""

    reasons: tuple[str, ...]


@dataclass(frozen=True)
class Answer:
    """An answerer's conversation comment, or an answerer's submitted review with a body."""

    kind: Literal["conversation comment", "review"]
    post: Post


@dataclass(frozen=True)
class Resolved:
    by: Reviewer


@dataclass(frozen=True)
class ThreadReply:
    post: Post


@dataclass(frozen=True)
class TopLevelReply:
    answer: Answer


Evidence = Resolved | ThreadReply | TopLevelReply


@dataclass(frozen=True)
class Answered:
    evidence: Evidence


@dataclass(frozen=True)
class Unanswered:
    pass


@dataclass(frozen=True)
class NotFeedback:
    """Only answerers wrote it."""


Verdict = Answered | Unanswered | NotFeedback


@dataclass(frozen=True)
class Verdicts:
    threads: dict[str, Verdict]
    reviews: dict[int, Verdict]
    conversation: dict[int, Verdict]


TIME_FIELDS = {"submittedAt": "submitted", "createdAt": "created", "lastEditedAt": "edited"}


def parse_time(value: object, what: str) -> datetime | Unreadable:
    """A timezone-aware time, so that comparisons are between moments and never between strings."""
    if not isinstance(value, str):
        return Unreadable((f"{what} is {value!r}, not a timestamp",))
    try:
        moment = datetime.fromisoformat(value)
    except ValueError:
        return Unreadable((f"{what} {value!r} is not a timestamp",))
    if moment.tzinfo is None:
        return Unreadable((f"{what} {value!r} has no timezone",))
    return moment


def parse_post(label: str, node: dict, posted_key: str) -> Post | Unreadable:
    """`posted_key` names the field that holds when the post went public."""
    times: list[datetime] = []
    posted_at: datetime | None = None
    reasons: list[str] = []
    for key in dict.fromkeys((posted_key, "createdAt", "lastEditedAt")):
        raw = node.get(key)
        if key == "lastEditedAt" and raw is None:
            continue
        match parse_time(raw, f"{label}'s {TIME_FIELDS[key]} time"):
            case Unreadable(found):
                reasons.extend(found)
            case datetime() as moment:
                times.append(moment)
                if key == posted_key:
                    posted_at = moment
    if reasons:
        return Unreadable(tuple(reasons))
    assert posted_at is not None, f"{label} parsed with no posted time"
    return Post(
        PostId(node["databaseId"]), parse_reviewer(node.get("author")), posted_at, max(times)
    )


def parse_thread_comment(node: dict) -> Post | NotPosted | Unreadable:
    label = f"thread comment {node['databaseId']}"
    match node.get("state"):
        case "SUBMITTED":
            return parse_post(label, node, "createdAt")
        case "PENDING":
            return NotPosted(parse_reviewer(node.get("author")))
        case state:
            return Unreadable(
                (
                    f"{label}'s state is {state!r}, neither PENDING nor SUBMITTED, so whether it "
                    "was posted is unknown",
                )
            )


def parse_review(node: dict) -> Post | NotPosted | Unreadable:
    if node.get("state") == "PENDING" or node.get("submittedAt") is None:
        return NotPosted(parse_reviewer(node.get("author")))
    return parse_post(f"review {node['databaseId']}", node, "submittedAt")


def thread_verdict(
    posts: tuple[Post, ...], resolved_by: Reviewer | None, answerers: Answerers
) -> Verdict:
    """`posts` are the thread's posted comments; `resolved_by` is None while it is unresolved."""
    if all(answerers.includes(post.author) for post in posts):
        return NotFeedback()
    if resolved_by is not None:
        return Answered(Resolved(resolved_by))
    replies = [post for post in posts if answerers.includes(post.author)]
    if not replies:
        return Unanswered()
    reply = max(replies, key=lambda post: post.posted_at)
    others = [post for post in posts if post is not reply]
    # Strictly before, so a post or edit in the same moment as the reply counts as new feedback.
    if any(post.changed_at >= reply.posted_at for post in others):
        return Unanswered()
    assert answerers.includes(reply.author), f"thread reply {reply.id} is not an answerer's"
    assert all(post.changed_at < reply.posted_at for post in others), (
        f"thread reply {reply.id} is not after every other comment's last change"
    )
    return Answered(ThreadReply(reply))


def item_verdict(feedback: Post, answers: tuple[Answer, ...], answerers: Answerers) -> Verdict:
    """For a review body or conversation comment. `answers` are sorted oldest first."""
    if answerers.includes(feedback.author):
        return NotFeedback()
    # Strictly after, so an answer in the same moment as the feedback's last change ignores it.
    answer = next((a for a in answers if a.post.posted_at > feedback.changed_at), None)
    if answer is None:
        return Unanswered()
    assert answerers.includes(answer.post.author), f"answer {answer.post.id} is not an answerer's"
    assert answer.post.posted_at > feedback.changed_at, (
        f"answer {answer.post.id} is not after feedback {feedback.id} last changed"
    )
    return Answered(TopLevelReply(answer))


def not_posted_verdict(author: Reviewer, answerers: Answerers) -> Verdict:
    """A post that was never submitted: the run drafts a reply rather than skip feedback."""
    return NotFeedback() if answerers.includes(author) else Unanswered()


def judge_discussion(discussion: Discussion) -> Verdicts | Unreadable:
    """Give every review, thread and conversation comment one verdict before anything prints, or
    name every value that could not be read."""
    answerers = discussion.answerers
    reasons: list[str] = []

    thread_posts: dict[str, tuple[Post, ...]] = {}
    for thread in discussion.threads:
        posts: list[Post] = []
        for node in thread["comments"]["nodes"]:
            match parse_thread_comment(node):
                case Unreadable(found):
                    reasons.extend(found)
                case NotPosted():
                    pass
                case Post() as post:
                    posts.append(post)
        thread_posts[thread["id"]] = tuple(posts)

    reviews: dict[int, Post | NotPosted] = {}
    for node in discussion.reviews:
        match parse_review(node):
            case Unreadable(found):
                reasons.extend(found)
            case Post() | NotPosted() as review:
                reviews[node["databaseId"]] = review

    conversation: dict[int, Post] = {}
    for node in discussion.conversation:
        match parse_post(f"conversation comment {node['databaseId']}", node, "createdAt"):
            case Unreadable(found):
                reasons.extend(found)
            case Post() as post:
                conversation[node["databaseId"]] = post

    if reasons:
        return Unreadable(tuple(reasons))

    bodies = {node["databaseId"]: (node.get("body") or "").strip() for node in discussion.reviews}
    candidates = [Answer("conversation comment", post) for post in conversation.values()] + [
        Answer("review", review)
        for rid, review in reviews.items()
        if isinstance(review, Post) and bodies[rid]
    ]
    answers = tuple(
        sorted(
            (a for a in candidates if answerers.includes(a.post.author)),
            key=lambda a: a.post.posted_at,
        )
    )

    def review_verdict(review: Post | NotPosted) -> Verdict:
        match review:
            case Post():
                return item_verdict(review, answers, answerers)
            case NotPosted(author):
                return not_posted_verdict(author, answerers)
            case _:
                assert_never(review)

    def resolver(thread: dict) -> Reviewer | None:
        return parse_reviewer(thread.get("resolvedBy")) if thread["isResolved"] else None

    verdicts = Verdicts(
        threads={
            thread["id"]: thread_verdict(thread_posts[thread["id"]], resolver(thread), answerers)
            for thread in discussion.threads
        },
        reviews={rid: review_verdict(review) for rid, review in reviews.items()},
        conversation={
            cid: item_verdict(post, answers, answerers) for cid, post in conversation.items()
        },
    )

    # Only answerers wrote what is marked as theirs, so no reviewer's post is hidden as `n/a`.
    for thread_id, verdict in verdicts.threads.items():
        if isinstance(verdict, NotFeedback):
            assert all(answerers.includes(p.author) for p in thread_posts[thread_id]), (
                f"thread {thread_id} is marked n/a but holds a reviewer's comment"
            )
    for items, verdict_of in ((reviews, verdicts.reviews), (conversation, verdicts.conversation)):
        for item_id, item in items.items():
            if isinstance(verdict_of[item_id], NotFeedback):
                assert answerers.includes(item.author), f"{item_id} is marked n/a but is feedback"

    return verdicts


def iso(moment: datetime) -> str:
    return moment.astimezone(UTC).isoformat().replace("+00:00", "Z")


def describe_evidence(evidence: Evidence) -> str:
    match evidence:
        case Resolved(by):
            return f"resolved by {login_of(by)}"
        case ThreadReply(post):
            return f"reply {post.id} by {login_of(post.author)} at {iso(post.posted_at)}"
        case TopLevelReply(Answer(kind, post)):
            return f"{kind} {post.id} by {login_of(post.author)} at {iso(post.posted_at)}"
        case _:
            assert_never(evidence)


def answered_line(verdict: Verdict | None, item: str) -> str:
    assert verdict is not None, f"{item} is printed with no verdict"
    match verdict:
        case Answered(evidence):
            text = f"yes ({describe_evidence(evidence)})"
        case Unanswered():
            text = "no"
        case NotFeedback():
            text = "n/a (yours)"
        case _:
            assert_never(verdict)
    return f"  answered   : {text}"


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
    return json.loads(result.stdout)["data"]


def fetch_discussion(target: str, owner: str, name: str, number: int) -> Discussion:
    """Page every list to its end. Exits rather than return a picture with anything missing."""
    collected: dict[str, list[dict]] = {key: [] for key, _ in LISTS}
    cursors: dict[str, str | None] = {key: None for key, _ in LISTS}
    answerers: Answerers | None = None
    for _ in range(MAX_PAGES):
        data = fetch_page(target, owner, name, number, cursors)
        page = data["repository"]["pullRequest"]
        if answerers is None:
            answerers = parse_answerers(target, data)
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

    assert answerers is not None, "the first page set the answerers"
    return Discussion(collected["threads"], collected["reviews"], collected["comments"], answerers)


def parse_answerers(target: str, data: dict) -> Answerers:
    viewer = (data.get("viewer") or {}).get("login")
    if not isinstance(viewer, str) or not viewer:
        raise SystemExit(
            f"error: GitHub's response for {target} has no viewer login, so this run cannot tell "
            "its own replies from a reviewer's"
        )
    return Answerers(parse_reviewer(data["repository"]["pullRequest"]["author"]), viewer)


def main() -> None:
    args, repo_arg = take_option(sys.argv[1:], "--repo")

    if not args:
        print("Usage: fetch_pr_comments.py <pr-number> [--repo OWNER/NAME]", file=sys.stderr)
        sys.exit(1)

    pr_number = int(args[0])
    name_with_owner, owner, name = get_repo(repo_arg)
    target = f"{name_with_owner}#{pr_number}"
    discussion = fetch_discussion(target, owner, name, pr_number)
    # Judged before the first print, so a value that cannot be read leaves no half output.
    match judge_discussion(discussion):
        case Unreadable(reasons):
            raise SystemExit(
                f"error: cannot tell which feedback on {target} is already answered, so nothing "
                "was printed:\n" + "\n".join(f"  - {reason}" for reason in reasons)
            )
        case Verdicts() as verdicts:
            print_discussion(target, discussion, verdicts)


def print_discussion(target: str, discussion: Discussion, verdicts: Verdicts) -> None:
    threads = discussion.threads
    reviews = discussion.reviews
    conversation = discussion.conversation

    # Printed so the reply step can be checked against the same target these ids came from.
    print(f"# Source: {target}")
    # Printed so a wrong viewer or PR author, which would change every verdict, can be seen.
    print(f"# Answerers: {discussion.answerers.describe()}")
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
        r
        for r in reviews
        if (r.get("body") or "").strip() or threads_by_review.get(r["databaseId"])
    ]:
        rid = review["databaseId"]
        reviewer = parse_reviewer(review.get("author"))
        state = review["state"]
        body = (review.get("body") or "").strip()
        review_threads = threads_by_review.get(rid, [])
        n = len(review_threads)

        print(HEAVY)
        print(f"# REVIEW by {login_of(reviewer)} ({state})  [review_id: {rid}]")
        # Commit is null when the reviewed commit no longer exists, e.g. after a force-push.
        commit = (review.get("commit") or {}).get("oid") or "unknown"
        print(f"# commit {commit}  submitted {review.get('submittedAt') or 'unknown'}")
        print(HEAVY)
        print(f"  thank      : {thank_line(reviewer)}")
        print(f"  refer_as   : {refer_as(reviewer)}")
        if body:
            print(answered_line(verdicts.reviews.get(rid), f"review {rid}"))
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
                print(answered_line(verdicts.threads.get(thread["id"]), f"thread {thread['id']}"))
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
                        replier = login_of(parse_reviewer(reply.get("author")))
                        print(f"    {replier}: {reply['body'].strip()}")
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

            opener = login_of(parse_reviewer(first.get("author")))
            print(f"COMMENT [{comment_idx}]  {opener} @ {first['path']}:{line}")
            print(f"  comment_id : {first['databaseId']}")
            print(
                f"  thread_id  : {thread['id']}  (resolved: {'yes' if thread['isResolved'] else 'no'})"
            )
            print(f"  outdated   : {'yes' if thread['isOutdated'] else 'no'}")
            print(answered_line(verdicts.threads.get(thread["id"]), f"thread {thread['id']}"))
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
                    replier = login_of(parse_reviewer(reply.get("author")))
                    print(f"    {replier}: {reply['body'].strip()}")
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
            reviewer = parse_reviewer(comment.get("author"))
            print(f"CONVERSATION COMMENT  {login_of(reviewer)}")
            print(f"  thank      : {thank_line(reviewer)}")
            print(f"  refer_as   : {refer_as(reviewer)}")
            print(f"  comment_id : {comment['databaseId']}")
            print(f"  url        : {comment['url']}")
            print(f"  created    : {comment['createdAt']}")
            print(f"  edited     : {comment.get('lastEditedAt') or 'no'}")
            cid = comment["databaseId"]
            print(answered_line(verdicts.conversation.get(cid), f"conversation comment {cid}"))
            print()
            print("  BODY:")
            print(indent(comment["body"].strip(), "    "))

        print()
        print(HEAVY)
        print()


if __name__ == "__main__":
    main()
