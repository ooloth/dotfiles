---
description: Fix type errors with expressive type annotations.
---

Use one or more type-error-fixer agents to systematically fix all type errors - if specified, just focus on the errors found here: $ARGUMENTS

When there are many errors, divide the errors into batches (e.g. by type error or by file) and resolve them in parallel using one type-error-fixer agent per batch when each batch can be fixed in parallel without creating conflicts.
