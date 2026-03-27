---
name: review-documentation
description: Perform a documentation review to identify stale and missing text and visuals in this project that are misleading or risk inconsistent future choices. Use when asked to identify opportunities improve the system's documentation or make the system easier to understand and maintain.
---

## Context

1. Study the `conventions-for-documentation` reference skill guidance
2. Study the current project's defined documentation guidance (if any)

## Your task

1. Use up to 50 subagents to explore all documentation (including files, code comments and diagrams) in the current codebase (or subsection if the user specified a smaller scope)
2. Identify opportunities to fix style violations
3. Identify inconsistent patterns for a category with no defined convention and what existing (or other) convention might be worth defining
4. Focus especially on patterns you would not want a future agent to spread
