---
name: conventions-for-python
description: Python patterns and style guide (when alternate patterns are not specified at the project level). TRIGGER when writing, editing, or reviewing Python (.py) files.
model: haiku
effort: low
paths: "**/*.py"
---

## Type hints

- Do not quote return types; if using Python < 3.14, add: `from __future__ import annotations`

## Style guide

- Prefer `match` statements over `if...elif` chains referencing the same variable
- Leverage `assert_never` in the default `match` statement block to make exhaustive case handling explicit

Apply these conventions to the current task.
