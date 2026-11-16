---
number: 015
status: accepted
date: 2026-11-15
---

# 015 — Each factory stage starts by invoking `factory-ticket-to-pr` with its stage

## Forced by

The planning and build stages share their rules on what a run may post, what it decides alone and
when it escalates, and the planner starts the build in a new session
([#291](https://github.com/ooloth/dotfiles/issues/291)). Two copies of those rules had already
drifted apart ([#273](https://github.com/ooloth/dotfiles/issues/273)).

## Decision

`/factory-ticket-to-pr <owner/repo#issue> [plan-only]` plans, and
`/factory-ticket-to-pr build <owner/repo#issue> <run-id>` builds. The skill's `SKILL.md` holds the
shared rules, and each stage's steps sit beside it in `plan.md` and `build.md`, read only by the
session running that stage.

## Rejected

- **A skill per stage.** Each stage could be invoked by its own name. It is rejected because the
  shared rules would belong to one stage's skill, and the other would reach into it.

## Revisit when

A stage stops sharing the rules, or ticket-to-PR gains a third stage.
