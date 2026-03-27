---
name: review-types
description: Assess the expressiveness, accuracy and cohesion of the project's current static type annotations. Use when asked to identify opportunities to improve how well the type system is being used to ensure correctness and/or express the intent of the code in domain-specific terms.
---

## Context

1. Study the `conventions-for-types` reference skill guidance
2. Study the current project's documented static typing guidance (if any)

## Your task

1. Use up to 50 subagents to explore the current codebase (or subsection if the user specified a smaller scope)
2. Look for missing type annotations
3. Look for inaccurate or overly broad types
4. Look for use of primitive types where domain-specific types could express the intent more clearly
5. Focus especially on identifying anti-patterns you would not want a future agent to spread
