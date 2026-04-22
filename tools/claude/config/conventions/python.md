# Python

## Ideal state

### Type hints

- Do not quote return types; if using Python < 3.14, add `from __future__ import annotations`

### Control flow

- Prefer `match` statements over `if...elif` chains referencing the same variable
- Use `assert_never` in the default `match` block to make exhaustive case handling explicit

## Common failure modes

- Quoted return type annotations
- `if...elif` chains that could be expressed more clearly as `match` statements
- Non-exhaustive `match` statements missing `assert_never` in the default case
