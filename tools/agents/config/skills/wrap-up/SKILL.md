---
name: wrap-up
description: End a session by confirming every action it mentioned was dealt with, then finding what in the codebase and the backlog would mislead the next agent. Reports both and fixes only what the user approves.
disable-model-invocation: true
effort: high
model: opus
---

## Scope

Start from the parts of the codebase this session worked in, and follow them outward to whatever
they affect that a fresh agent would meet. That includes comments in distant files that describe
this code, docs and agent instructions that describe it (`CLAUDE.md`, `AGENTS.md`, READMEs,
CONTRIBUTING, decision records), and callers or tests that rely on how it works. To find them,
search the repo for the names of what the session changed, renamed, moved or deleted. Judge each
file by what it says now, not by what changed in it.

The scope also covers claims about the future that this session's work bears on: open tickets in
the project's tracker, question files in `docs/questions/`, decision records not yet accepted, and
docs that describe a planned or unfinished state. Read the whole open backlog, not only search
results, because tickets describe intent in concepts rather than identifiers. Load the tracker's
skill (`use-gh`, `use-jira` or `use-linear`) before reading, so the read includes comments and
relationships such as parent and blocked-by. The single fetch in "Order of work" is that read, and
subagents work from its file. To find docs describing a planned or unfinished state, list
`docs/questions/` and `docs/decisions/` (or their equivalents) and search the docs and agent
instructions for words such as "future", "planned", "not yet", "TODO" and "WIP".

A problem that predates the session is still in scope when it sits in a file the scope covers and
a fresh agent working there would hit it. Mark it as pre-existing.

The full transcript of this session is at `~/.claude/projects/<cwd-slug>/<session-id>.jsonl` if you
need to check what was said. The slug is the starting directory with `/` and `.` replaced by `-`.
The session ID is the name of the scratchpad's parent directory. The directory names start with
`-`, so from inside `~/.claude/projects`, glob them as `./*/*.jsonl`, or tools like grep read them
as options. Messages are the records whose top-level `type` is `user` or `assistant`. A `user`
record is something the user typed only when its `message.content` is a string and it has no
`isMeta: true`. Subagent transcripts are under `<session-id>/subagents/`.

## Order of work

The wait is set by the slowest subagent, so start the subagents first:

1. Build the scope, running its searches several per turn.
2. Fetch the whole open backlog once, with comments and relationships, into a scratch file. For
   GitHub: `gh issue list -R <owner>/<repo> --state open --limit 1000 --json
   number,title,body,comments,labels,parent,blockedBy,blocking,subIssues > <file>`.
3. Launch every subagent described under Step 2, in a single message.
4. While they run, do Step 1, your own list from Step 2, and the repo's own checks (from
   CONTRIBUTING or its equivalent).
5. Check each subagent's findings as it arrives.

## Step 1: Account for every action

List every action that came up in the session:

- What the user asked for, including requests made in passing inside longer messages
- What you said you would do ("I'll also", "later", "next", "follow-up")
- Questions you asked that the user never answered
- Approvals the user gave that you never acted on
- Tool calls that failed or were denied and were never retried or worked around, including calls
  whose output looked fine but hid an error, such as empty output with stderr discarded

Give each one exactly one status, with its evidence:

- **Done:** the commit, `file:line` or URL that shows it
- **Deferred:** where it is recorded (a ticket, a `docs/questions/` file)
- **Dropped:** the user's words deciding that
- **Open:** none of the above. An item the user never ruled on is Open, even when they approved a
  list that left it out.

## Step 2: Find what would mislead the next agent

Run these four at the same time.

**Your own list.** You know things a fresh reader cannot: what you renamed, what you started and
did not finish, which name fitted the first plan but not what got built, and which gotcha you hit
that nothing in the repo records. Finding stale claims is mostly your job. A stale claim reads as
current to a reader who does not know what changed. For each thing the session changed, renamed,
moved or deleted, search for every claim about it.

**A fresh subagent.** Give it the in-scope file list and the checklist below, and nothing from this
session's conversation. Tell it to read the files itself, to follow them into related files wherever
that helps, and not to spawn subagents of its own. If the list is too long for one agent to read in
a few turns, split it across several fresh subagents. Ask it: "You are about to start work in this
part of the codebase. Starting from these files, what would you believe that is not true, what
looks unfinished, and what is named or placed in a way that would send you in the wrong direction?
Give a file and line for each."

**A cold reader.** Give it only the repo path. Ask it: "You are a new agent starting work on the
repo at `<path>`, with no prior context. Read what you would naturally read to orient yourself,
starting from whatever entry point you would choose, and stop once you know what you would do next.
Then report what you would do next and what told you to, which files you read and in what order,
and what confused you, contradicted itself, looked stale, or would have led you astray if you had
trusted it, with a file and line for each."

Grade its answer against what you know the next step is. It passes only if it picks the right next
thing for the right reason. A right answer reached from a wrong signal fails, because that signal is
what the next agent will follow. When it names a procedure, such as a skill to run, grade where
that procedure would lead. When the right next step is not written anywhere a fresh agent would
look, that is a finding in itself: propose where to record it.

**A backlog subagent.** Give it a short summary of what this session changed and decided, the path
to the backlog file, and the list of intent files from the scope. Tell it to read each one in full
itself and not to spawn subagents of its own. If the backlog is too large for one agent, split it
across several by ticket number.
Ask it to return each item the session's changes bear on, quoting the claim and saying which
applies: its premise is now false, its approach is now ruled out or was built differently, it
states a rule the code now breaks or argues against a rule the code now enforces, it is done or
obsolete but still open, or its dependencies changed.

A conflict between a ticket's rule and the code is always a decision for the user.

Launch every subagent with the Agent tool's `model` set to `"opus"`. What a subagent never reads
cannot appear as a finding, so a faster model that skims costs misses nobody sees.

Tell every subagent to make its independent reads and searches several per turn, not one at a time,
and to report in at most 400 words, one finding per line as `location | claim | why it misleads`.
If more findings exist than fit, it says how many it left out.

Check every subagent finding against the code before keeping it. Keep a list of the ones you reject
and why.

Your own list and the fresh subagent both look for:

- Comments, docstrings, READMEs and agent instruction files (`CLAUDE.md`, `AGENTS.md`, skills) that
  are no longer true
- TODOs, stubs, skipped tests, dead code and commented-out code
- Two coexisting ways of doing the same thing, where the next agent could copy the wrong one
- Names of files, functions, types or docs that no longer describe what they hold
- Docs that narrate history (the words `documentation.md` bans, such as "used to", "previously",
  "no longer", "originally") rather than describing the present
- Decision records, question files or standards that the session's changes made stale
- Learnings that exist only in the conversation and belong in a project doc
- Uncommitted or untracked changes a fresh agent could not tell were intended
- A false claim kept with a correction further down, instead of replaced. The fix states the true
  thing where the topic is first raised, then searches the repo for the same claim elsewhere.
- A figure that appears in several files, where the copies disagree
- A question file whose answer now exists elsewhere, still marked open
- A doc that contradicts a recorded decision
- A README or doc describing a check its script does not implement
- A change in progress that is not flagged where a reader will meet it

## Step 3: Report and stop

Send one message with:

1. **The cold read:** what it would do next, the signal it followed, and whether that passes.
2. **The ledger:** a table of every action from step 1, with its status and evidence.
3. **The tidy findings:** for each, the location, what is misleading, the proposed change, and
   whether it is a fix you can make or a decision for the user. Lead with whatever would actively
   mislead. A confident wrong signal comes before a gap, because a gap announces itself. For a
   ticket, the proposed change is a draft comment, description rewrite or status change, with its
   exact wording. Draft a description rewrite with `write-ticket-description`.
4. **Rejected subagent findings:** each one, with the reason you rejected it.
5. **Out-of-scope problems you noticed,** listed briefly and not fixed.

Then stop and wait.

## Step 4: Apply what the user approves

Make the approved fixes in the working tree, then name each file you changed and say what the
change does. Do not commit, post, or close anything. Each of those needs its own signal from the
user. A ticket change is posted only after the user approves its exact wording.
