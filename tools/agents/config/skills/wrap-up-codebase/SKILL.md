---
name: wrap-up-codebase
description: Find everything in the repo that a change made untrue or that would mislead the next agent, and sort each finding into a fix, a question for the user, or a dismissal. Changes nothing itself; the caller acts on the list. Run it once before opening a draft PR, once per session before asking for the commit signal on the session's last change in a repo that commits straight to its default branch, and from wrap-up.
effort: high
model: opus
---

This skill finds and sorts. It edits nothing, commits nothing and posts nothing: whoever invoked it
acts on the list it returns, because what to do with a fix depends on who is waiting.

## The change

On a feature branch, the change is the branch against the default branch
(`git diff <default>...HEAD`). In a repo that commits straight to its default branch, it is the
working tree against `HEAD` plus any commits this session made. Name the range you used in the
list's first line.

## Scope

Start from what the change touched, and follow it outward to whatever a fresh agent would meet that
describes it: comments in distant files, docs and agent instructions (`CLAUDE.md`, `AGENTS.md`,
skills, READMEs, CONTRIBUTING), decision records and question files, and callers or tests that rely
on how it works. Search the repo for the names of what the change added, renamed, moved or deleted,
several searches per turn. Judge each file by what it says now, not by what changed in it.

The scope also covers docs in the repo that describe planned or unfinished work this change bears
on: question files in `docs/questions/`, decision records not yet accepted, and anything that says
"future", "planned", "not yet", "TODO" or "WIP". A problem that predates the change is still in
scope when it sits in a file the scope covers and a fresh agent working there would hit it. Mark it
as pre-existing.

The tracker is out of scope. `wrap-up-backlog` covers tickets.

## Three checks, run at once

The wait is set by the slowest subagent, so build the scope, launch both subagents in one message,
and make your own list while they run. Launch each with the Agent tool's `model` set to `"opus"`,
because what a subagent never reads cannot become a finding. Tell each to make its reads and
searches several per turn, not to spawn subagents of its own, and to report one finding per line as
`location | claim | why it misleads`, with nothing else.

**Your own list.** You know what a fresh reader cannot: what you renamed, what you started and did
not finish, which name fitted the first plan but not what got built, and which gotcha you hit that
nothing in the repo records. For each thing the change touched, search for every claim about it.

**A fresh subagent.** Give it the in-scope file list and the checklist below, and nothing from this
session. Tell it to read the files itself and to follow them into related files wherever that
helps. Split a long list across several. Ask it: "You are about to start work in this part of the
codebase. Starting from these files, what would you believe that is not true, what looks
unfinished, and what is named or placed in a way that would send you in the wrong direction? Give a
file and line for each."

**A cold reader.** Give it only the repo path, plus any extra question the caller passes. Ask it:
"You are a new agent starting work on the repo at `<path>`, with no prior context. Read what you
would naturally read to orient yourself, starting from whatever entry point you would choose, and
stop once you understand how the repo works. Then report which files you read and in what order,
and what confused you, contradicted itself, looked stale, or would have led you astray if you had
trusted it, with a file and line for each." Orienting from the entry points is what sends it past
the README, the agent instructions and CONTRIBUTING, where stale claims about a change show up.

Your own list and the fresh subagent both look for:

- Comments, docstrings, READMEs and agent instruction files that are no longer true
- TODOs, stubs, skipped tests, dead code and commented-out code
- Two coexisting ways of doing the same thing, where the next agent could copy the wrong one
- Names of files, functions, types or docs that no longer describe what they hold
- Docs that narrate history (the words `documentation.md` bans, such as "used to", "previously",
  "no longer", "originally") rather than describing the present
- Decision records, question files or standards that the change made stale
- Learnings that exist only in the conversation and belong in a project doc
- A false claim kept with a correction further down, instead of replaced. The fix states the true
  thing where the topic is first raised, then searches the repo for the same claim elsewhere.
- A figure that appears in several files, where the copies disagree
- A question file whose answer now exists elsewhere, still marked open
- A doc that contradicts a recorded decision
- A README or doc describing a check its script does not implement
- A change in progress that is not flagged where a reader will meet it

Check every subagent finding against the files before keeping it.

## Sort each finding

**Fix:** there is one clearly correct answer. The test is whether applying it requires the user to
make a choice; if not, it is a fix. Obvious corrections, consistency with the pattern used
everywhere else, and the mechanical part of a mixed finding are all fixes. A fix carries the exact
edit: the file, the old text and the new text.

**Ask:** the right answer depends on a decision only the user can make. Several valid approaches
depend on requirements or preferences; the fix would change a public interface, a data shape or a
contract; or it needs intent only the user has. Every finding in an agent instruction file is an
ask, because editing one waits for the user's approval. Answer every analytical sub-question
yourself, by reading or by a read-only query, so the ask is only the decision: never ask whether
something is a bug. Each ask gives at least two lettered options with what each would do, and marks
one recommended.

When a finding has a mechanical part and a decision, the mechanical part is a fix and only the
decision is an ask.

**Dismiss:** a subagent finding that does not hold up against the files, with the reason.

## Return

One list, in this order:

1. **The cold read:** the files it read in order, and its answer to any extra question the caller
   passed.
2. **Fixes,** each with its location, what misleads, and the exact edit. Lead with whatever would
   actively mislead: a confident wrong signal before a gap, because a gap announces itself.
3. **Asks,** each with its location, what misleads, and its lettered options with one recommended.
4. **Dismissed,** each with the reason.
5. **Out-of-scope problems noticed,** listed briefly.
