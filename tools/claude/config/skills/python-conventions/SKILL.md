---
name: python-conventions
description: Python patterns and style guide (when alternate patterns are not specified at the project level)
---

## Type hints

- Do not use `assert` for runtime type narrowing; raise an appropriate error instead
- Do not quote return types; if using Python < 3.14, add: `from __future__ import annotations`

## Style guide

- Place imports at the top of the module, not inline
