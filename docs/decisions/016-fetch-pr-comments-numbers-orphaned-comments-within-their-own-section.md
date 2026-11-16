---
number: 016
status: accepted
date: 2026-11-16
---

# 016 — `fetch_pr_comments.py` numbers orphaned comments within their own section

## Forced by

[#237](https://github.com/ooloth/dotfiles/issues/237): the script's comment labels counted past
their own total, because one counter ran across every review and the orphaned-comments section.
Once each review numbers its own comments `[1 of n]` to `[n of n]`, the orphan section, which
belongs to no review, needs a numbering of its own. Before the fix it printed `[k]`, continuing the
shared counter with no total.

## Decision

The orphaned-comments section numbers its comments `[1 of m]` to `[m of m]`, where `m` is the
number of orphaned threads printed. Among the options weighed, it wins because every label's
position stays within a printed total, a new review leaves the orphan labels unchanged, and the form
matches every review's labels. It assumes each review numbers its own comments.

## Rejected

- **Keep `[k]`, continuing the counter shared with the reviews.** It changes nothing in the code.
  It is rejected for two reasons. The label has no total, so a reader cannot check a position
  against one. And a new review with inline comments shifts every orphan's `k`, so a fresh fetch
  compared with a saved one shows unchanged orphaned comments as changed. It reverses if a reader
  needs orphan labels to keep the old `[k]` form.
- **Restart at 1 with no total, `[i]`.** It stops the count carrying over from the reviews, so a new
  review does not change any orphan label. It is rejected because there is no total to check the
  position against, and the form differs from every other label, which all have totals. It reverses
  if the reviews' labels also drop their totals, so that `[i]` would match every other label.
- **Continue the global count against a grand total of every printed thread, `[4 of 5]`.** Every
  label then sits within a printed total. It is rejected because every new review with inline
  comments raises the grand total and so changes every orphan label, so a fresh fetch compared with
  a saved one shows unchanged orphaned comments as changed. The chosen option avoids that: a new
  review changes no orphan label. It does not avoid every change, since a new orphaned comment
  still changes the orphan totals (see Risk). The grand-total option reverses if orphan labels must
  count across the whole output, such as a reader matching an orphan by its position in the full
  listing.

## Risk

A label such as `[1 of 1]` now repeats across reviews and the orphan section, so a label alone does
not identify a comment. None of the skills that read the output refers to a comment by its label.

A new orphaned comment changes every orphan label's total, so `[1 of 1]` becomes `[1 of 2]`. A
comparison of fresh output against saved output shows changed orphan labels when an orphan is added.

## Revisit when

Something starts referring to a comment by its label, needs an orphan's position in the whole
output, or the reviews stop numbering their own comments.

## Also update

- [x] `tools/agents/config/skills/review-pr-comments-converge/scripts/fetch_pr_comments.py` — the
  orphan loop prints `[i of m]`
