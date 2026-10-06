---
name: next
description: Recommend what to work on next in this repo. TRIGGER at the start of a session, or when the user asks what to work on next and you are not already partway through something.
---

Recommend one to three things to work on next, say why, and stop. The user decides.

## Where work lives

- **In progress:** uncommitted changes in the working tree (`git status`).
- **Issues:** the GitHub tracker. Kind labels are `bug`, `feature` and `maintenance`. A feature
  spanning several issues is grouped in a milestone, or under a parent issue. Invoke `use-gh`
  before any `gh` call.
- **Open questions:** `docs/questions/`, one file per question.

## Priority

1. Uncommitted changes
2. Bugs
3. Features already started: a milestone or parent issue with some of its issues closed
4. Maintenance
5. New features
6. Questions, once no issues remain or if any can no longer be deferred

Who filed an issue does not affect its rank. If the top candidate depends on a decision nobody has
made, that decision comes first.

Within a rank, weigh how often the problem affects the user and how bad it is when it does, and use
the cost to fix as the tiebreak. Say which of these decided each recommendation.

If nothing is left anywhere, say so and offer `scan-gaps`.
