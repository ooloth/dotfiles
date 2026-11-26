---
name: prioritize
description: Rank the actions toward a goal the user names, such as a category of work and the ideal state it should reach, by cost of delay against size, including steps nobody has tracked yet, as a table with the reason for each rank. TRIGGER when the user says what they care about and asks what to do first, today or this week, to get there. When they have no goal in mind, or ask where they left off, use `next` instead.
argument-hint: '<scope> [toward <ideal state>]'
model: opus
effort: high
---

Rank the actions toward the user's goal, give the reason for each, and stop. The user decides what
to do. Read `~/.agents/standards/prioritization.md` before ranking: it is the rule every rank here
follows. Where a project's own docs say what makes delay costly there, they take precedence.

## 1. Pin down the goal

State in one or two lines:

- **Scope:** the board, project, repos or category. It can span several repos, or none.
- **Ideal state:** what is true when the goal is reached, specific enough to check.

Take each from the user's words and the project's docs. Ask only for what you cannot infer, and
when the user named only a category, propose an ideal state from the project's docs for them to
confirm. Wait for the answer before gathering.

## 2. Gather what is tracked

Find every tracked item in scope: tickets on the trackers the scope names, epics and their
children, work in flight (branches, open PRs, unpushed commits) and docs that plan the goal, such
as plans, decision records and open questions. Invoke the matching `use-*` skill before the first
call to each tracker. Read each item's state, comments and relationships, not only its body, since
the body is a brief and cannot show whether anyone started.

When there are more items than you can read yourself, give subagents bounded lists of items, a
scratch folder each from `mktemp -d`, and an instruction to read the items themselves without
starting subagents of their own.

## 3. Map the path

Compare the ideal state with the current state and list every step between them. Read the current
state from the system: the code, the running service, the docs. Checking only reads. Anything that
installs, downloads, or writes outside a `mktemp -d` folder is proposed to the user as a step, not
run. Where the scope has no repo, read it from ticket comments and the state of linked PRs. Mark
each step tracked, with its link, or untracked. A tracked item whose step is already done is stale.

## 4. Check before ranking

Apply the standard's Musts to every step. Check the top candidates, and anything whose metadata
disagrees with its consequences, against the system itself. Mark the rest as ranked on their
tickets alone.

## 5. Report

Open with the goal as pinned down in step 1, and whether the path is fully tracked. Then one table
of the top 10 steps:

| #   | Action | Tracked | Why now | Size | Unblocks |
| --- | ------ | ------- | ------- | ---- | -------- |

- **Tracked:** the link, or `untracked`.
- **Why now:** the one sentence that decided the rank, in plain words.
- **Size:** small, medium or large compared with the other rows, with what it was judged from,
  such as `small: one file, no unknowns` or `large: three repos, waits on another team's review`.
  Never a time.

While the path has untracked steps, row 1 is tracking them: tasks under the epic that holds the
goal, or a new epic when no single one does, unless an item is causing harm now. The order is the
advice: wherever the user stops, the rows above that point are the most valuable work for what it
took. Below the table, list the remaining steps in rank order by name and link only.

After the table, list separately so the user can overrule each:

- items ranked on their tickets alone
- ties and unknowns, with the fact that would settle each
- metadata that disagrees with consequences, such as a `priority: low` on a live breach
- stale items, with the evidence

## 6. Discuss

Answer questions about the ranking and re-rank on what the user adds. Offer to draft the epic and
tasks for untracked steps with `write-ticket-description`. Change nothing in any tracker, metadata
included, until the user approves that exact change.
