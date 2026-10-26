---
name: next-step
description: Recommend the few pieces of work that are actually needed to reach a goal, keep them in order, and keep pointing at the next one to finish as the day goes on.
argument-hint: '<the outcome you want to be true, optionally with tickets you think matter>'
disable-model-invocation: true
---

Goal: $ARGUMENTS

You plan; the user does the work, in other sessions. You do not start, message or watch them.

## Your job

Find the smallest set of work items that makes the goal's outcome true. Most candidate tickets will
sound important and many overlap; leave out everything the outcome does not need, and say why in a
line, grouping where that helps, so the user can check the cut. Missing a critical piece and keeping
an unneeded one are the two failures that matter most. Then put the set in order and say briefly
why each item sits where it does. Finish work already in flight before anything new.

As the day goes on, keep the list pointed at the next thing to finish. Something found along the
way is recorded, not acted on: note it in the plan's Scratch section, or suggest a ticket for it,
and move it into the set only if the outcome needs it more than what is there. Do not offer to fix
it now.

When an item is close to shipping, work out how to prove it works in its environment. Merged is
not done.

## Starting or resuming

Look for the goal's plan in `~/Repos/ooloth/content/plans/`. If that folder doesn't exist on this
machine, say so and stop. Match the goal against the part of each folder's name after the date, so a
plan started on an earlier day is still found. List the folder names only. When one looks like a
match, name it and ask the user whether to resume it, and open no `plan.md` and read nothing else
until they answer, because researching the wrong plan wastes the session. That reply is only the
question: it has no table and saves no plan. If the goal has no plan yet, start one. If it has one,
read it, then read each item's ticket, PRs and branch again. In your first reply, show every place
where the plan disagrees with what you read. The tracker wins: update the plan to match.

Read the instruction files (`CLAUDE.md`, `AGENTS.md`) of every repo the goal touches. Claude Code
loads them only from the folder a session starts in and the folders above it, so the others have to
be read explicitly.

## Every reply

1. The table: `# | Item | Waits on | Next action | Whose | Why here`, one row per item in order.
2. When the reply asks the user to carry out a next action that takes more than one step, the
   steps under the table: numbered, saying who does each and what it should show, and what you will
   check once the user reports back. Give them in full even when an earlier reply already gave
   them, never as a pointer such as "the steps from my last reply", because the user reads the
   latest reply and an earlier one may be lost in scrollback. A reply that does not ask the user to
   do the action next leaves its steps out.
3. A few short observations, only what changed or matters now.
4. Numbered yes/no questions, each with your recommendation, about the top item or about anything
   whose answer would change the set or the order. Otherwise "Nothing".

## The plan file

The plan is for the next session. It holds what a fresh session would otherwise get wrong or have
to redo. Keep it at `~/Repos/ooloth/content/plans/<YYYY-MM-DD>-<ticket-or-slug>/plan.md`. The date
is the day the plan was started, and it stays the same when a later session resumes the plan, so the
folders sort by age and a plan left running is easy to spot. The plan holds:

- the user's outcome, in their words, word for word
- when each item's state was last read from the tracker
- the table, where "Why here" gives only the reason for the item's position; what the item is
  belongs on its ticket
- "Left out": each candidate left out of the set, or each group of them, with the reason in a line
- "Open questions": the questions from your last reply that are not answered yet, with your
  recommendations. When one is answered, put the answer into the table or the plan and remove the
  question
- "Scratch": findings that are not on a ticket yet
- "Steps": for each item whose next action is the user's and takes more than one step, the
  numbered steps a reply would give, so a fresh session can give them again word for word. Remove
  an item's steps when it moves on

Nothing else: no history of changes, no record of past agreements, no steps for an item before its
next action is the user's. Write each paragraph or list item on one line. Save the file after every
reply, so ending the session needs nothing more. Don't pull, commit or push in that repo.

## Changes outside the plan

The plan is never committed, but this session sometimes changes other files, such as these
instructions after a reply went wrong. A reply that reports such a change names each file and what
its change does, then asks, as a numbered question, whether to commit it now, before the next item
is taken up. The commit still waits for the user's answer.

## Approval

The user agrees to the set and the order before work starts, and again when either changes.
Anything written where other people read it, such as a ticket comment, waits for the user's
approval of its exact text.
