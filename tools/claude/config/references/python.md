# Python

Python-specific invariants. Read alongside the general reference files.

## Must

**Return types are not quoted.**
Add `from __future__ import annotations` at the top of any file targeting
Python < 3.14 rather than quoting return type annotations. Quoted annotations
are harder to read and unnecessary with the future import.

**`match` is used instead of `if/elif` chains.**
When branching on the same variable across multiple conditions, `match` is used
rather than a chain of `if/elif`. It is more readable and enables exhaustiveness
checking.

**`match` blocks are exhaustive.**
The default case of every `match` statement calls `assert_never` to make
exhaustive handling explicit. A new variant added to the matched type becomes
a type error, not a silent fallthrough.
