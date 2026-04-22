---
name: review
description: Review a specific concern in the codebase. TRIGGER when the user asks you to review or assess code or recommend improvements.
argument-hint: '[e.g. pr # | architecture | code-style | documentation | observability | tests | types | conventions]'
model: opus
effort: high
---

## Dispatch

Check the concern the user specified:

- `pr` → Invoke the `review-pr` skill
- `conventions` → Invoke the `review-conventions` skill
- For any other concern, continue below

## Context

1. Identify which standards to load:
   - If the user specified a concern, load `~/.claude/conventions/<concern>.md`
   - Otherwise, list `~/.claude/conventions/` and load whichever files are relevant to the current codebase or the user's stated focus
   - State which standards files you loaded before proceeding
2. Study the current project's documented guidance for those concerns (if any)

## Your task

1. Use up to 50 subagents to explore the codebase (or subsection if the user specified a smaller scope)
2. Identify deviations from the ideal state and instances of the failure modes in the standards file
3. Focus especially on patterns you would not want a future agent to spread
