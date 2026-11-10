---
number: 013
status: accepted
date: 2026-11-10
---

# 013 — The unattended implementation records each one-way decision the planner took

## Forced by

[Decision 012][012] lets `plan-unattended` take one-way decisions and list them under "Decided
without you" in a ticket comment. Three rules then disagree about where such a decision lives. The
`design` skill's Phase 7 has a decision settled during design link a record that is committed and
pushed. My global `CLAUDE.md` says a choice others will build on is never settled in a comment.
`plan-unattended` commits nothing. Before 012 these decisions escalated, so the conflict never came
up. After it, a decision would live only in a comment on a ticket that closes, and a later session
checking `docs/decisions/` would not find it.

## Decision

`implement-unattended` commits a decision record for each "Decided without you" entry, in the
folder where the repo keeps its records and in that folder's format, built from the entry's
decision, options, reason and what would reopen it. The records land in the draft PR's diff, where
I review them with the code. In a repo with no record folder, the entries go in the PR body
instead. The planner's entry stands in for the record link until then.

## Rejected

- **The "Decided without you" entry is the record.** It needs no new step, and the entry already
  holds a record's fields. It is rejected because a later session reads the repo's record folder,
  not closed tickets, so it could reverse the decision without knowing it existed. It reverses if
  sessions come to read ticket comments as part of the decision listing.
- **The planner writes the records on a branch.** The record would exist as soon as the decision
  did. It is rejected because planning commits nothing, and the implementation already creates the
  branch the PR reviews. It reverses if planning gains its own branch.
- **Not yet: leave the conflict until `implement-unattended` is aligned with 012.** It is what
  exists. It is rejected because every planned run until then would leave decisions with no
  record, and nothing would show which ones.

## Risk

A record built from a one-line entry can be thinner than one written by hand. A repo without a
record folder keeps the decision only in a PR body.

## Revisit when

A draft PR from an unattended run carries a record too thin to explain its decision, or one for a
decision that was not one-way.

## Also update

- [x] `tools/agents/config/skills/implement-unattended/SKILL.md` — step 5 commits the records
- [x] `tools/agents/config/skills/plan-unattended/SKILL.md` — "How the comments read" says the
  entry stands in for the record link

[012]: 012-the-unattended-planner-takes-one-way-decisions-and-asks-only-what-the-repo-cant-settle.md
