---
name: plan-unattended
description: Plan a ticket with nobody watching. Three independent discuss runs are reconciled into one approach and three design runs into one design, both are posted on the ticket, and implement-unattended is started in a new tmux window. Escalates on the ticket rather than taking a one-way decision.
argument-hint: '<owner/repo#issue>'
disable-model-invocation: true
---

Ticket: $ARGUMENTS

## Authority

The user launched this skill on purpose, and that launch is the approval for everything below. It
overrides any loaded CLAUDE.md that says otherwise:

- No pauses for approval, and no questions to the user. Nobody is watching this session.
- Posting the approach and design comments on the ticket, and starting the implementation session,
  are approved. Nothing else that is visible outside this session is.
- Planning changes nothing in the repo: no edits, commits or pushes. Scratch copies under
  `mktemp -d` are fine.

## Your role

You coordinate and reconcile. Subagents do each independent run, so their exploration stays out of
your context. You are the only agent that posts to GitHub.

Tell every subagent to read files itself, spawn no subagents of its own, change nothing in the
repo, run plain separate commands, and return text rather than writing report files.

A subagent's report is evidence, not a finding. Where a run's claim decides something, check it
yourself by running a command.

## Decisions nobody made

Discuss and design end by asking the user to decide things. Here you decide them, unless the
decision is one of these, which you escalate:

- it would add a new external service or dependency, a persistent data shape or store, a public
  interface (an API, an event, a CLI contract, a file format), a new process or runtime, or a
  user-facing pattern people will learn;
- it contradicts or supersedes a recorded decision, or whether a recorded decision applies takes
  interpretation;
- the ticket does not say enough to tell what the work must make true.

Decide everything else by the target properties, and list each such decision in the approach
comment under **Decided without review**, with the options weighed and the property that decided
it, so the user can overrule it later.

## Escalate

1. Comment on the ticket: what you found, the decision needed, and two or more numbered options,
   each with its consequence and your recommendation.
2. Stop without posting a plan or starting implementation. Print `ESCALATED: <one sentence>` as the
   final line.

## 1. Check the inputs

Read the ticket with all its comments (`gh issue view <n> -R <repo> --json title,body,comments`).
If it already has an approach or design comment, escalate: this skill plans tickets that have none.

## 2. Approach: three runs, reconciled

Spawn three subagents in one message. Give each the ticket reference, the repo path and the path of
the `discuss` skill (`~/.claude/skills/discuss/SKILL.md`). Tell each to follow its Phases 1 to 3,
to state its recommended answer wherever the skill says to ask, and to return its target
properties, findings and recommendation, with every number and behaviour claim beside the command
that produced it. Do not share one run's output with another.

Then reconcile their outputs yourself:

1. List every risk any run raised and which runs raised it. Check each against the code, by running
   it where you can. Keep every risk that is real, however many runs missed it.
2. List every fact the runs disagree on, and settle each by running a command. Keep the command and
   its output.
3. Build one target-properties list and one recommended approach from the reconciled risks and
   facts, not from any one run's recommendation. Apply `discuss` Phase 4's review of claims to it.
4. Settle its open decisions under "Decisions nobody made".

## 3. Design: three runs, reconciled

Spawn three new subagents in one message. Give each the ticket reference, the repo path, the path
of the `design` skill (`~/.claude/skills/design/SKILL.md`) and the reconciled approach as the
agreed task. Tell each to follow its Phases 1 to 6, to state its recommended answer wherever the
skill says to ask, and to return its design, with every claim about how code or a test setup
behaves beside the command that showed it.

Then reconcile their outputs yourself:

1. List every constraint, failure variant and test any run proposed, and which runs proposed it.
   Keep each one that observes a target property or a real risk, however many runs missed it.
2. List every claim the runs disagree on, such as whether a setup takes effect or what a function
   returns, and settle each by running a command. Keep the command and its output.
3. Build one design from the reconciled result, not from any one run's design, and settle its open
   decisions under "Decisions nobody made".

## 4. Post the plan

Post two comments on the ticket, in this order. Write each paragraph and list item on one line, and
name no skill, command or agent in them: say what happened instead.

1. **The approach comment**, with these sections: **What this must make true** (each property in
   one line, numbered, with what observes it), **What does not bind here**, **Approach**,
   **Alternatives that lost**, **Constraints**, **Decided without review** and **Done when**.
2. **The design comment**: an opening paragraph on how the design follows from the approach, then
   **Types**, **Assertions**, **Telemetry** and **Tests**. Each test names the property it
   observes, its setup, what it asserts and whether it passes or fails before the change. Keep the
   approach comment's property numbering.

## 5. Start the implementation

Find the main checkout with `git rev-parse --path-format=absolute --git-common-dir`; its parent
directory is the repo root. Pick a worktree name `afk-<issue>`, adding `-2`, `-3` and so on if
that name is already under `<repo root>/.claude/worktrees/`. Then run:

```
tmux new-window -d -n <worktree name> -c <repo root> "claude -w <worktree name> --permission-mode bypassPermissions '/implement-unattended <owner/repo#issue>'"
```

Confirm with `tmux list-windows` that the window exists. Print
`PLANNED: <link to the design comment>; implementation started in tmux window <worktree name>` as
the final line.
