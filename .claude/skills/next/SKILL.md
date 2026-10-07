---
name: next
description: Recommend what to work on next in this repo, ranked by cost of delay. TRIGGER at the start of a session, or when the user asks what to work on next and you are not already partway through something.
---

Recommend one to three things to work on next, say why, and stop. The user decides.

## Cost of delay decides

Every item is ranked by its cost of delay: the pain, slowness, loss or harm that users and
developers meet on each day the problem stays, times how often they meet it. How long the work
would take is not part of it.

Each kind of work has a cost of delay that behaves predictably, which is why kind sets the default
order below:

- **Work in flight** costs developers every day it waits: context is lost, branches go stale, and
  conflicts accumulate, while nothing it was meant to deliver reaches anyone.
- **Bugs** cause pain or harm each time someone meets them.
- **Started features** leave users without something already partly built, and the partial work
  decays like work in flight.
- **Maintenance** problems slow or mislead every later session, so fixing them before new work
  starts spares that work the cost.
- **New features** cost users the workaround they use each day without them.
- **Questions** cost nothing on their own. They carry the cost of delay of the work they block.

Kind is the default, and cost of delay is the rule it stands in for. An item moves across a kind
boundary only when you can say in one sentence why its cost of delay breaks the default, and that
sentence goes in the report.

## Where work lives

- **In flight:** uncommitted changes (`git status`), a branch other than `main`, and open PRs
  (`gh pr list`).
- **Issues:** the GitHub tracker. Kind labels are `bug`, `feature` and `maintenance`. A feature
  spanning several issues is grouped in a milestone, or under a parent issue. Invoke `use-gh`
  before any `gh` call.
- **Open questions:** `docs/questions/`, one file per question.

## Priority

1. Work in flight: uncommitted changes, a branch other than `main`, or an open PR
2. Bugs
3. Features already started: a milestone or parent issue with some of its issues closed
4. Maintenance
5. New features
6. Questions, once no issues remain or if any can no longer be deferred

Who filed an issue does not affect its rank. If a top candidate depends on a decision nobody has
made, that decision comes first. Check this only for the candidates you are about to recommend,
never across the whole tracker. An unmade decision appears as a `docs/questions/` file the issue
cites, or as an open decision recorded in the issue itself.

Within a rank, weigh how often the problem affects the user and how bad it is when it does. Say
which of these decided each recommendation, including any cost-of-delay sentence that moved an
item across a kind boundary.

If nothing is left anywhere, say so and offer `scan-gaps`.
