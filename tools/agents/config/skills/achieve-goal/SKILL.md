---
name: achieve-goal
description: Drive a goal with a checkable "done" through to done, doing every step that is unblocked and approved, watching what it starts, and keeping one numbered table of the remaining steps in every reply. TRIGGER when the user asks to get one or more tasks to done, ship and verify a set of PRs, or drive a multi-step goal through to done.
argument-hint: 'The outcome you want to be true, such as "get these three tickets to done"'
---

Goal: $ARGUMENTS

You drive the goal to done yourself. Do every step that is unblocked and already approved, and ask
the user only for decisions and side effects nobody has approved yet. Naming the goal approves the
reading and the planning, not the side effects: each merge, deploy, delete or post is approved the
way the skill that owns it requires, usually by the user's own words for that item. Ask for those
approvals early and together, so the work can run while the user is away: one message can approve
several named items for later, such as invoking the owning skill once per PR "at the ideal time",
and you carry each out when its row is unblocked. Hand each kind of work to the skill that owns it
and repeat none of its rules: merging and proving in production to `merge-and-verify`, other proofs
to `prove-it-works`, PRs to `create-pr`, tickets to `write-ticket-description`, reviews to the
review skills.

A goal can be tasks with reviewed PRs, a migration, a data fix or an investigation. Done means the
outcome holds where it runs, shown by evidence. Merged is not done.

## Taking stock

Read before asking. For each task, read its ticket, PRs, review state, CI and what is already
deployed, and the instruction files (`CLAUDE.md`, `AGENTS.md`) of every repo the goal touches. Find
what orders the work:

- a change stacked on another
- a deploy one change needs before another
- a data or config step between merges
- a step only a person can do, such as a login, a look at a page, or a bypass

Also read what changes once a change lands: the repo's merge method and review rules (what a
squash merge does to a stacked change), and how the pipeline builds and deploys (whether a newer
build cancels an older one, how long a rollout takes).

Leave out what the outcome does not need, and say why in a line, so the user can check the cut. Ask
only for what none of this holds.

## Every reply

1. **The table:** `# | Step | Status | Waiting on | Whose`, one row per step in order, in full every
   time, so a user returning from time away can find their place.
2. **Pending for you:** every action only the user can take, in full each time, never "see above",
   with the result to expect. Approvals and decisions go in Questions instead. A link must work as
   clicked: check a hand-built link against the target app's own rules for valid links before
   giving it.
3. **Questions** last, numbered, each with your recommendation and phrased so a bare "yes" has one
   meaning. With none, say so.

## Pace and timing

- Settle only the next unclear row. Fill in later rows as they get close.
- Do unblocked, approved work at once, without asking.
- Batch changes that restart the same deployment, so it restarts once. A batch works only when the
  pipeline folds back-to-back merges into one build and one rollout, so confirm that first.
- Never start a change while the previous one's rollout would be cut short by it. Cancelling a
  build that has not started rolling out, so a newer build carries both, is how a batch works.

## Watching

Schedule a check for anything you started that finishes later, as a one-shot `CronCreate` the way
the global `CLAUDE.md` describes. Once anything you started is running, open every reply with
**✅ All fine** or **🔴 Problem: ...**, so a user returning from time away sees the state at a
glance. Never revert or change anything deployed on your own: say what you would do and wait.

## State

There is no plan file. The state lives in the systems themselves (tracker, PRs, CI, deployments) and
in the table each reply repeats. A resumed session rebuilds the table by reading those systems
again.

## Found work

Something found along the way that the outcome does not need becomes a proposed ticket, not work
done now. It joins the table only if the outcome needs it.

## Checks that catch real mistakes

- A pipeline or CI "success" is not proof the work ran. Check the step actually ran.
- Before reading sensitive data, check where the output of that read will go.
- A browser check that needs a login runs where the user can see it, or goes to them by hand with
  an exact link.
- A fact from an earlier check is checked again before it is repeated.
- When something fails, read why before assuming the obvious cause.

## Closing

Each task closes when its proof holds. At the end, offer a short list of what shipped, ready to
paste, with every ticket and PR linked.
