---
name: review-architecture
description: Perform an architecture review to identify anti-patterns that are at risk of spreading. Use when asked to identify opportunities to make the system easier to understand and maintain.
effort: high
---

## Context

1. Study the `conventions-for-architecture` reference skill guidance
2. Study the current project's documented architecture intentions

## Your task

1. Use up to 50 subagents to explore the current codebase (or subsection if the user specified a smaller scope)
2. Identify opportunities to improve the architecture, shape, boundaries and interfaces connecting the current system
3. Look for import patterns that suggest poor boundaries or poor folder and module organization which could be improved
4. Look for patterns that would make it difficult to add or remove features safely as the system evolves
5. Look for any code that does not represent a good example for humans or agents to follow
6. Focus especially on patterns you would not want a future agent to spread
