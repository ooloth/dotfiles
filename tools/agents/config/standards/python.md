# Python

Python-specific invariants. Read alongside the general reference files.

## Must

**Type annotations on every function signature, enforced by `ty` in CI.**
All function parameters and return types are annotated. `ty` (by Astral) runs in CI
with strict settings. Unannotated or `# type: ignore`-annotated code does not merge.

**Newtypes for domain-meaningful primitives.**
`NewType` wraps bare `int`/`str` for IDs and other domain values. `ty` rejects
substituting one for another. Bare primitives are not passed across domain boundaries.

**Frozen dataclasses for domain types.**
`@dataclass(frozen=True)` on all domain structs. Immutability is the default;
mutation requires explicit justification.

**Sum types via `dataclass` variants and a union type alias.**
Sealed state machines use one `@dataclass(frozen=True)` per variant, combined into
a union alias (`TaskState = Pending | InProgress | Done`). This enables exhaustive
`match` and makes invalid states unrepresentable.

**`match` is used instead of `if/elif` chains.**
When branching on the same variable across multiple conditions, `match` is used
rather than a chain of `if/elif`. It is more readable and enables exhaustiveness
checking.

**`match` blocks are exhaustive.**
The default case of every `match` statement calls `assert_never` to make
exhaustive handling explicit. A new variant added to the matched type becomes
a type error, not a silent fallthrough.

**External data is validated at the boundary with Pydantic.**
All data entering from outside the process (API responses, env vars, config files,
CLI args) passes through a Pydantic model before entering domain code. Nothing
unvalidated crosses the boundary.

**Results are returned, not raised.**
The `result` library (`Ok`/`Err`) is used instead of exceptions for expected failure
paths. `try/except` is reserved for system boundaries and truly unexpected errors.

**Import architecture is enforced by `import-linter` in CI.**
A `.importlinter` contract defines which packages may import from which others,
mirroring the intended layering (e.g. `api → domain`, never `domain → api`).
`lint-imports` runs in CI. A violation fails the build.

## Should

**`beartype` is enabled in tests.**
`beartype` adds runtime type enforcement that catches what `ty` misses at the
boundary between typed and untyped code. Enable it in the test suite, not in
production.

**Return types are not quoted.**
Add `from __future__ import annotations` at the top of any file targeting
Python < 3.14 rather than quoting return type annotations. Quoted annotations
are harder to read and unnecessary with the future import.

## In scope

- All .py files in the repo

## Out of scope

- Auto-generated .py files
- Vendored Python code not maintained in this repo
