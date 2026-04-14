---
name: review-tests
description: Assess the current coverage and patterns across all tests in the project. Use when asked to identify opportunities to improve how well the system's behaviour is confirmed by its tests.
effort: high
---

## Context

1. Study the `conventions-for-tests` reference skill guidance
2. Study the current project's documented testing intentions (if any)

## Your task

1. Use up to 50 subagents to explore the current codebase (or subsection if the user specified a smaller scope)
2. Identify opportunities to improve the overall approach used for testing and how tests seem to be designed (or seem not to be)
3. Look for untested code
4. Look for code that is unnecessarily difficult to test, leading to missing or less meaningful tests (e.g. due to excessive mocking)
5. Look for missing or under-used testing approaches (e.g. unit, snapshot, property-based, integration, e2e, mutation)
6. Look for opportunities to make existing tests easier to understand (e.g. by reducing duplication via helper functions, consolidating tests with the same assertion into a single test that iterates over multiple related example input-output scenarios)
7. Focus especially on identifying anti-patterns you would not want a future agent to spread
