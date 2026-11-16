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

- **Keep `[k]`, continuing the counter shared with the reviews.** It leaves the orphan
  labels as they were. It is rejected because the label has no total, so a reader cannot check a
  position against one. It reverses if something starts reading orphan labels by their old position
  across the output.
- **Restart at 1 with no total, `[i]`.** It stops the count carrying over from the reviews. It is
  rejected for the same reason: there is no total to check the position against, and the form
  differs from every other label. It reverses if the reviews' labels also drop their totals, so that
  `[i]` would match every other label.
- **Continue the global count against a grand total of every printed thread, `[4 of 5]`.** Every
  label then sits within a printed total. It is rejected because every new review shifts every
  orphan label: the new review adds threads before the orphan section and raises the grand total,
  which fails P2 from #237 (a new review leaves the labels printed for earlier reviews unchanged).
  It reverses if something needs a whole-output count, for example to detect truncated output.

## Risk

A label such as `[1 of 1]` now repeats across reviews and the orphan section, so a label alone does
not identify a comment. None of the skills that read the output refers to a comment by its label;
they use `comment_id`, `thread_id`, and file and line.

A new orphaned comment changes every orphan label's total, so `[1 of 1]` becomes `[1 of 2]`. A
comparison of fresh output against saved output shows changed orphan labels when an orphan is added.

## Revisit when

Something starts referring to a comment by its label, reads orphan labels by their old position
across the whole output, or the reviews stop numbering their own comments.

## Also update

- [x] `tools/agents/config/skills/review-pr-comments-converge/scripts/fetch_pr_comments.py` — the
  orphan loop prints `[i of m]`
