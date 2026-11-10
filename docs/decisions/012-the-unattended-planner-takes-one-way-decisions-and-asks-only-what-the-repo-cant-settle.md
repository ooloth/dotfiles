---
number: 012
status: accepted
date: 2026-11-10
---

# 012 — The unattended planner takes one-way decisions and asks only what the repo can't settle

## Forced by

In the first round of planning replays, 6 of 11 graded runs stopped to ask instead of planning,
and every one was on a ticket that listed an open decision. The rule escalated by the category of
the question, so a question such as "what file format" escalated whatever the answer. In four of
those decisions the run's recommendation was the one my own plan chose, and three of those four
changed no recorded decision. The same ticket escalated in one run and planned in another. [#271](https://github.com/ooloth/dotfiles/issues/271),
[#269](https://github.com/ooloth/dotfiles/issues/269).

## Decision

`plan-unattended` takes every decision itself, one-way ones included. It first chooses the option
the target properties rank highest, then stops to ask only when that option changes a recorded
decision or depends on one that takes interpretation, needs work outside the ticket, or wins only
through my preference or a fact it cannot measure, or when the ticket does not say what the work
must make true. Each one-way decision it takes is listed under "Decided without you" in its
approach or design comment, and I overrule it at the draft PR. Attended sessions still leave
one-way decisions to me, and `implement-unattended` keeps its category list until implementation
replays give evidence.

## Rejected

- **Keep the categories, judged on the recommended option rather than the question.** It is the
  smallest change and keeps every new format and interface with me. It is rejected because any
  answer to a format question adds a format, so it still asks about decisions my plan matched, and
  a fresh agent applying it to a link opt-in question could not tell which way it went. It reverses
  if a later round shows one-way decisions the planner took alone that my plan would reject.
- **Decide everything, writing record amendments into the PR.** It never costs a night. It is
  rejected because record changes are where the planner's recommendation differed from my plan
  most often: two of the three record-changing decisions in round 1, one of them a recommendation I
  graded close to reject. It reverses if record-changing recommendations match my plans in later
  rounds.
- **Not yet: keep the category rule.** It is what exists. It is rejected because the same findings
  produced different verdicts in different runs, and it asked about three decisions whose
  recommendation matched my plan and changed no record. It reverses if the new rule asks about more
  decisions I didn't need than the old one.

## Risk

A one-way decision listed only in a comment can merge unread if I review the code without the
comments. Planning and implementation escalate by different rules until `implement-unattended` is
aligned.

## Revisit when

A replay round's per-decision grades, in each run's `grade.md` under `~/.local/state/replays/`,
show a decision the planner took alone that my plan would reject, or a question my plan didn't
need.

## Also update

- [x] `tools/agents/config/skills/plan-unattended/SKILL.md` — "Decisions nobody made" and "How the
  comments read" state this rule
- [x] #271 — its Decisions section links this record in place of the open question it settles
