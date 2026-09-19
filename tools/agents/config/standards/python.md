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

## Scripts

The standards above describe an application: a codebase with a domain model, layers worth
enforcing, and `ty`, `import-linter` and `beartype` running in CI. A dev script has none of those,
and applying them to one produces Pydantic models around four argparse flags. The rules below
replace them for scripts, and are held to just as firmly.

**A script is one file, run by `uv`, with its dependencies declared inline.**
PEP 723 metadata at the top and a `#!/usr/bin/env -S uv run --script` shebang. No virtualenv to
activate, no requirements file, no install step, and no ambiguity about which interpreter it wants.
A reader can run it from a fresh clone and an editor can resolve its imports.

**One file is the whole shape, not the starting shape.**
A script does not grow a helper module, a package directory, or a sibling it imports. When it needs
a second file, or something starts importing it, or it runs anywhere but a developer's machine, it
is an application and everything above this section applies to it. That transition is a rewrite and
saying so is the point: the cheap shape stays cheap because it is not allowed to creep.

**The module docstring says what the script does and how to run it.**
It is the only documentation a script gets, and `--help` is built from it. A reader decides from
those lines whether this is the tool they want.

**Every function signature is annotated.**
This survives the carve-out because it costs one line, needs no runtime, and is what makes a script
readable six months later. `ty` runs on a single file as happily as on a package.

**An expected failure exits with a sentence, not a traceback.**
Missing input, absent state, a precondition that does not hold: these end the run with a message a
human can act on and a non-zero status. `SystemExit("…")` is the idiomatic form. A traceback is
reserved for the genuinely unexpected, where the stack is the useful part.

**A script that mutates a developer's own state is reversible, and refuses when it would not be.**
Application code rarely edits the machine it runs on; scripts do it constantly, to caches,
databases, config and checkouts. So: back up before writing, provide the inverse operation, and
refuse to run rather than overwrite a backup that a previous run left behind. The refusal is the
feature. Nothing here is covered by the application standards because nothing there has this shape.

**`match` replaces an `if/elif` chain over one variable, without requiring `assert_never`.**
Exhaustiveness checking needs a sealed union, and a script branching over string literals has none.
The readability argument still holds; the type argument does not.

Not required of a script, and cluttering when added: Pydantic models at the boundary, the `result`
library, `NewType` wrappers, frozen dataclass domain types, `import-linter` contracts, `beartype`.
Argparse `choices` is the boundary validation a CLI needs.

## In scope

- Application `.py` files, for everything above the Scripts section
- Script `.py` files, for the Scripts section, which replaces the rest

## Out of scope

- Auto-generated .py files
- Vendored Python code not maintained in this repo
