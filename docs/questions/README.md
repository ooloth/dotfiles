---
updated: 2026-09-04
update_when: a decision is made, a question is split, or an active initiative changes
decays: fast
status: active
---

# Questions

The sibling of `../decisions/`: the decisions not yet made. A directory listing of this folder is
the full inventory — every filename asks its question plainly, so there's no separate index.

## What goes in a question file

One question per file, kebab-case name, phrased as the question. Six sections, always in this
order, present even when empty — an empty section is the reminder that nobody's looked yet:

1. **Why it matters** — what's blocked, or what gets expensive, if this is answered wrong.
2. **What would settle it** — the evidence, measurement, or event that ends the question. Not
   another question. A question that genuinely can't be worked until another is answered says so
   here, in prose, as part of describing what an answer requires.
3. **Resolves into** — where the answer lands (a decision, recorded in `../decisions/` once that
   folder exists).
4. **Source** — where the question came from, so it survives whatever raised it being deleted.
5. **Options** — each candidate answer, with its strongest case and its cost.
6. **Findings** — evidence gathered so far, written in as it's established, not batched at the
   end. Nothing here is settled fact until it graduates into a decision record — say so at the top
   of the section. Tag anything asserting a fact about the world: *Measured*, *Sourced*,
   *Reasoned*, or *Unverified* (somebody wrote it down and nobody can say why it's true — the most
   useful tag, because an unsourced claim reads exactly like a sourced one until tagged).

No "Blocked by" / "Blocks" fields on the file itself. A dependency between questions is stated in
prose under **What would settle it** instead — a per-file dependency graph goes stale invisibly
and gets trusted precisely because it reads as fact rather than judgement.

## Splitting and closing

A question resolves into as many decision records as it contains distinct decisions. Split it when
only part of it is actually blocking something — the blocking part becomes its own file, and the
rest stays where it belongs, keeping the same six-section format. Delete a question once nothing
is left in it that a decision record hasn't settled — mine its Findings first, since they don't
survive the deletion otherwise.

## Working on an active initiative

When several open questions belong to one current push, not just isolated one-offs, group them
under a heading naming that push's end state in one sentence, order them by what has to be
answered first, and say for each what actually breaks if it's skipped — not just that work "can't
start" or restating the topic. Leave anything not currently being pushed on as a flat, ungrouped
list; expanding it before it's next is planning against a system that doesn't exist yet.
