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
number of orphaned threads printed. Given that each review numbers its own comments, it is the only
option for this section that keeps every label's position within a printed total, and it matches the
form every review's labels use.

## Rejected

- **Keep `[k]`, continuing the counter shared with the reviews.** It leaves the orphan
  labels as they were. It is rejected because the label has no total, so a reader cannot check a
  position against one. It reverses if something starts reading orphan labels by their old position
  across the output.
- **Restart at 1 with no total, `[i]`.** It stops the count carrying over from the reviews. It is
  rejected for the same reason: there is no total to check the position against, and the form
  differs from every other label. It reverses if the reviews' labels also drop their totals, so that
  `[i]` would match every other label.

## Risk

A label such as `[1 of 1]` now repeats across reviews and the orphan section, so a label alone does
not identify a comment. The skills that read the output identify comments by `comment_id`,
`thread_id`, and file and line, not by label.

A new orphaned comment changes every orphan label's total, so `[1 of 1]` becomes `[1 of 2]`. A
comparison of fresh output against saved output shows changed orphan labels when an orphan is added.

## Revisit when

Something starts referring to a comment by its label, or reads orphan labels by their old position
across the whole output.

## Also update

- [x] `tools/agents/config/skills/review-pr-comments-converge/scripts/fetch_pr_comments.py` — the
  orphan loop prints `[i of m]`
