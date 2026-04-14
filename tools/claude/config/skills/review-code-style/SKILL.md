---
name: review-code-style
description: Perform a code style review to identify anti-patterns in this project that are at risk of spreading. Use when asked to identify opportunities to make the system easier to understand and maintain.
effort: high
---

## Context

1. Study the `conventions-for-code-style` reference skill guidance
2. Study the current project's documented code style guidance (if any)

## Your task

1. Use up to 50 subagents to explore the current codebase (or subsection if the user specified a smaller scope)
2. Identify opportunities to fix style violations
3. Identify inconsistent patterns for a category with no defined convention and what existing (or other) convention might be worth defining
4. Focus especially on patterns you would not want a future agent to spread
