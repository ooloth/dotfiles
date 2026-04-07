---
name: conventions-for-python
description: Python patterns and style guide (when alternate patterns are not specified at the project level). TRIGGER when writing, editing, or reviewing Python (.py) files.
---

## Type hints

- Do not quote return types; if using Python < 3.14, add: `from __future__ import annotations`

## Style guide

- Prefer `match` statements over `if...elif` chains referencing the same variable
