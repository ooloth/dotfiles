---
name: wrap-up-backlog
description: Find every ticket on the project's tracker that a change made false, finished or out of date, and sort each into a fix with its exact wording, a question for the user, or a dismissal. Changes nothing itself; the caller acts on the list. merge-and-verify runs it once the change is serving, and wrap-up runs it at the end of a session.
effort: high
model: opus
---

This skill finds and sorts. It posts nothing, edits no ticket and closes nothing: whoever invoked
it acts on the list it returns, because what to do with a fix depends on who is waiting.

## The change

Name what shipped or what the session changed: the PR and its commits, or the commits and working
tree a session produced, plus the ticket the work was on and every decision it settled. Say it in a
short summary, because the backlog describes intent in concepts, not identifiers.

## Read the whole open backlog

Load the tracker's skill first (`use-gh`, `use-jira` or `use-linear`), so the read includes
comments and relationships such as parent and blocked-by. Fetch the whole open backlog once into a
scratch file in a new `mktemp -d` directory. For GitHub:

```sh
gh issue list -R <owner>/<repo> --state open --limit 1000 \
  --json number,title,body,comments,labels,parent,blockedBy,blocking,subIssues > <file>
```

Read the whole backlog, not only search results, because a ticket can bear on the change without
naming anything it touched.

Give a backlog subagent the summary of the change, the path to the backlog file, and nothing else
from this session. Launch it with the Agent tool's `model` set to `"opus"`, tell it to read the
file in full itself and not to spawn subagents of its own, and split a large backlog across several
by ticket number. Ask each to return every ticket the change bears on, quoting the claim and saying
which applies:

- its premise is now false
- its approach is now ruled out, or was built differently
- it states a rule the code now breaks, or argues against a rule the code now enforces
- it is done, or obsolete, but still open
- its dependencies changed

Check each against the code and the change before keeping it.

## Sort each finding

**Fix:** there is one clearly correct update. The test is whether making it requires the user to
make a choice; if not, it is a fix. A ticket the change finished is closed, with a comment saying
what finished it. A false premise or a changed dependency gets a comment, or a description
rewrite drafted with `write-ticket-description`. A fix carries the ticket, the action (comment,
description rewrite, close, relationship change) and the exact text.

**Ask:** the right update depends on a decision only the user can make, such as whether a ticket is
still wanted now that its premise changed, or a conflict between a ticket's rule and the code. A
conflict between a ticket's rule and the code is always an ask. Answer every analytical
sub-question yourself, by reading or a read-only query, so the ask is only the decision. Each ask
gives at least two lettered options with what each would do, and marks one recommended.

**Dismiss:** a subagent finding that does not hold up, with the reason.

## Return

One list: the fixes with their exact text, the asks with their lettered options, and the dismissed
findings with their reasons.
