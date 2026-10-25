---
name: drive-goal
description: Find and keep revising the shortest safe path from a goal to a verified, shipped milestone, across tickets, repos and the running system. Use when the user names a goal (an epic, a milestone, an outcome or an existing plan file) and wants to know what to do next to reach it. Not for implementing a single ticket.
argument-hint: '<goal: an epic, milestone, outcome, or a docs/plans/ file to resume>'
disable-model-invocation: true
---

Goal: $ARGUMENTS

# Drive a goal

Your job is to minimize the time until the goal's next milestone is shipped and verified. Agent
utilization, ticket throughput and parallel work are not the measure.

You own the reasoning across tickets: which milestone comes next, the order of the work, whether
each ticket is still needed, and what proves the milestone is reached. Tickets own their approaches
and designs, and the single-ticket workflow (discuss, design, implement, review, PR) owns how each
one is built. You don't redo either.

You advise and the user carries out. Each step runs in its own session, which the user starts. This
skill does not start, message or watch other sessions.

## Operating rules

1. **Choose the milestone by cost of delay.** List the milestones the goal could reach next. For
   each, name who it unblocks and what they can do once it ships: the team can build X, users can
   try Y and give feedback, the user stops doing Z by hand. Choose the one whose delay costs the
   most per day, then find the shortest safe path to it. When a milestone outside the stated goal
   would unblock more, sooner, raise it as a question. Never switch goals on your own.
2. **Work backward from proof.** State the observable evidence that would prove the milestone is
   reached. Merged, deployed and verified in the environment are three different states, and only
   the last one proves a milestone.
3. **Finish the goal's work in flight first.** Before choosing anything new, list every in-flight
   item that belongs to the goal, with its last remaining step: open PRs, branches, worktrees, and
   tickets with an approach or design already posted. An approved PR with green checks merges
   before any new work starts. Work in flight is dropped only when the user agrees it is no longer
   wanted. Work outside the goal is not yours to schedule.
4. **Find the minimum credible path.** Separate true prerequisites from convenient improvements.
   Check each remaining ticket against the code and the tracker, because a ticket can already be
   done, duplicate another, or be made pointless by something that shipped or by another ticket on
   the path. Following a request that the evidence shows is wrong is a failure; say why instead.
5. **Reduce uncertainty early.** When a dependency or assumption could invalidate substantial work,
   the cheapest decisive experiment or check comes before speculative implementation.
6. **Choose one next action.** Default to one ticket in progress. Run work in parallel only when
   the items are independent and the time saved exceeds the cost of integrating and reviewing them.
7. **Verify independently.** An agent's report that something is done is not proof. Inspect the
   diff, test results, CI, PR, deployment and end-to-end evidence that apply. Never claim a check
   ran unless you observed its result.
8. **Replan on evidence.** Reassess after a shipped change, a failed verification, a new
   dependency, a changed requirement or a decision. Ask whether the remaining work is still needed.
   Don't replan merely to generate activity.
9. **Stop when done.** When the milestone's proof is observed, report the evidence, then propose
   the next milestone or stop. Never widen the scope silently.
10. **Ask only what the next step needs.** A question goes in a report only when its answer changes
    the next step or the one after it. Every other open question becomes a step on the path, placed
    just before the step whose shape it decides, such as "Decide how `deploy/run` detects a finished
    job", and is asked when that step reaches the front. A question asked early switches the user's
    context away from the work in front of them, and its answer rests on assumptions the earlier
    steps can still overturn.

## Approval

The user agrees to the milestone and the order before any step starts, and again whenever the
order changes. Every write to a tracker or anywhere other people read waits for the user's approval
of the exact text: closing a ticket as unneeded, editing a ticket body, setting `blockedBy` or
sub-issues, or posting a comment.

Reading needs no approval, with one exception. Before a read on another machine, such as over SSH,
or a read that uses the user's credentials for a service, such as an API key or a 1Password
session, name the read and what it touches, and wait for the user's go-ahead.

## Sources

Read the instruction files of every repo the goal touches. Claude Code loads `CLAUDE.md` only from
the folder a session starts in and the folders above it, so the main repo's file loads and every
other repo's file has to be read explicitly.

Then read what the path depends on: tickets with their comments, parents, sub-issues and blockers;
open PRs with their reviews and checks; git state, branches and worktrees; the running environment,
such as deploys, logs and daemons; and any other source the user names. Keep observed facts apart
from assumptions.

## The plan file

The plan lives at `docs/plans/<goal-slug>.md` in the goal's main repo, which is the repo of the app
the goal changes rather than its infrastructure repos. Sessions for the goal start in that repo.

- **Template:** copy `references/plan.md` from this skill. Never edit the template itself.
- **README:** if `docs/plans/README.md` does not exist, create it with this text:

  ```markdown
  # Plans

  Each file here is the working plan for one goal: its next milestone, the proof that the milestone
  is reached, the order of the work and the reasons for it. A plan is temporary. When its goal is
  reached, what it found is moved into tickets, decision records or standards, and the file is
  deleted.

  The tracker holds each ticket's state. A plan's State column is rebuilt from the tracker each
  session and is never the source of truth.
  ```

- **What it holds:** the reasoning the tracker has no place for, which is the milestone, its proof,
  why this order, the assumptions it rests on and what was found. It links to tickets, PRs, designs
  and decision records rather than copying them. A decision is recorded through the project's
  decision process, and the plan links to that record.
- **Resuming:** rebuild the State and Evidence columns from fresh reads, and flag every place where
  the file disagreed with them. Keep the reasoning unless new evidence replaces it.
- **Committing:** propose a commit of the plan file at the end of each session and whenever the
  order changes.
- **Finishing:** when the goal is reached, propose where each finding in the plan should go, then
  propose deleting the file.

## Loop

1. **Orient.** Find the goal's plan file, or create one. Read the sources. List the work in flight.
   Choose the milestone and its proof.
2. **Decide.** Choose the next action. Say why it comes next, what it unlocks and what evidence
   would change the order. When a decision needs the user, give the options, the evidence, your
   recommendation and what each option does to the path. Then wait for agreement.
3. **Advance.** Give the user the next step: the ticket, the brief for the session that will do it,
   and what that session should report back. The brief carries only what the ticket doesn't say,
   such as findings from this plan and constraints from other tickets on the path.
4. **Reconcile.** When the user returns, read the tracker, git state and verification evidence
   again. Update the order and the reasons where the evidence changed them, record the next action,
   and save the plan before yielding.

## Reporting format

Keep the status short:

**Milestone:** the outcome, who it unblocks, and how much of its proof is observed.

| Order | Step | State | Why now / what it unlocks |
| ----- | ---- | ----- | ------------------------- |
| 1     | ...  | ...   | ...                       |

**In flight:** each in-flight item and its last remaining step, or "None".

**Next:** one recommended action and why.

**Changed:** new evidence or changes to the order, if any.

**Need from you:** the numbered yes/no questions the next one or two steps depend on, each with your
recommendation, or "Nothing".

## Boundaries

- Don't create tickets merely to make the plan look complete.
- Don't start more work because a session is idle.
- Don't mark a milestone verified on merged code or an agent's summary alone.
- Don't keep a second copy of a ticket's implementation details.
- Don't present the dependency chain as a duration estimate. When the evidence on duration is weak,
  call the path the best current hypothesis and revisit it.
