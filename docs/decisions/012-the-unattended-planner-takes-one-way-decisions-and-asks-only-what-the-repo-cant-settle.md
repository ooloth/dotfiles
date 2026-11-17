---
number: 012
status: accepted
date: 2026-11-10
amended: 2026-11-15
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
one-way decisions to me, and `implement-unattended` keeps its category list until graded
implementation runs give evidence.

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

At a draft PR I overrule a one-way decision the planner took alone, or a run stops to ask me
something it didn't need to.

## Also update

- [x] `tools/agents/config/skills/plan-unattended/SKILL.md` — "Decisions nobody made" and "How the
  comments read" state this rule
- [x] #271 — its Decisions section links this record in place of the open question it settles
- [x] `tools/claude/replay.py` — the grade template's Decisions section records the per-decision
  grades that "Revisit when" reads

## Addendum (2026-11-10) — a new dependency or service waits for review

A review of this rule found that `implement-unattended` escalates only decisions the design did not
make. A dependency the planner chose would be installed, and its install scripts run, on my Mac
before I had seen the choice. So when a decision listed under "Decided without you" adds a new
dependency or external service, the planner posts its plan and does not start the implementation.
Other one-way decisions still start it. "Revisit when" also changed the same day, before any round
ran: it fired on a single question my plan didn't need, while the rejected options reverse only on
more such questions than the old rule asked.

## Addendum (2026-11-10) — narrower triggers, and records for decisions taken

The same review found two triggers that let one case go either way, so both were narrowed. Work
outside the ticket escalates only when a binding property needs it; a cause-level fix nothing
needs goes under Deferred. A fact the planner cannot measure escalates only when meeting a binding
property rests on it; a fact that only changes the ranking goes under Assumptions. A one-way
decision taken alone no longer lives only in a comment: [decision 013][013] has the implementation
commit a record for it, so it shows in the draft PR's diff, which narrows the Risk above.

## Addendum (2026-11-10) — what the per-decision grades count

The grade template's Decisions section counts escalations, one-way decisions taken alone, listed or
not, and decisions taken alone that the rule says to escalate. A design choice that is none of
these goes under Missed or Found, because the stage verdicts already grade plan quality. "Revisit
when" names the same scope. Before this, it read 'a decision the planner took alone that my plan
would reject'.

[013]: 013-the-unattended-implementation-records-each-one-way-decision-the-planner-took.md

## Addendum (2026-11-15) — revisited from real runs, not replay grades

Planning is no longer replayed and graded against my own plans: the factory runs from ticket to
draft PR on real tickets, and what each run gets wrong becomes a change to its skills
([#268](https://github.com/ooloth/dotfiles/issues/268)). The replay harness and its `grade.md`
files are gone, so "Revisit when" now reads: at a draft PR I overrule a one-way decision the
planner took alone, or a run stops to ask me something it didn't need to.

## Addendum (2026-11-15) — one rule set for both stages

`plan-unattended` is now the planning stage of `factory-ticket-to-pr`
([#291](https://github.com/ooloth/dotfiles/issues/291)). Its rules for deciding and escalating
moved to that skill's `SKILL.md`, and the build stage follows them too, so the build takes the
one-way decisions the design left open and escalates under the same conditions as planning
([#273](https://github.com/ooloth/dotfiles/issues/273)).

## Addendum (2026-11-16) — one-way means a triage test holds

"Revisit when" fired at the first draft PR, [#293](https://github.com/ooloth/dotfiles/pull/293): I
overruled a decision the planner classed as one-way because "a file format" covered a label only
agents read. `factory-ticket-to-pr` no longer keeps its own list of one-way categories. It triages
each open choice with the three tests in the global `CLAUDE.md`'s "A choice found mid-work", decides
it either way, and lists only those a test held for under "Decided without you".

## Addendum (2026-11-17) — the factory asks nothing

A run no longer escalates a decision. It decides from the target properties and puts what an
attended session would ask into the draft PR, where closing the PR reverses it. It stops only where
review would come too late (harm before review, a new dependency's code, work it cannot verify) or
there is nothing for a PR to hold. The first two runs showed why: #237 escalated over a decision
record's wording, and #262 escalated over a case its own approach had already resolved.
