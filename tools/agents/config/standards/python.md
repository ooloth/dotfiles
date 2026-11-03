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
The default case of every `match` over a union or an enum calls `assert_never`
to make exhaustive handling explicit. A new variant added to the matched type
becomes a type error, not a silent fallthrough. A `match` over an open set of
values, such as an `int` or a `str`, ends in a wildcard case that handles the
rest.

**External data is parsed at the boundary into domain types.**
Data entering from outside the process (CLI arguments, environment variables,
files, subprocess output, API responses) is turned into the `NewType`s, frozen
dataclasses and unions the domain code uses, in one function per source.
Nothing typed `Any`, a raw `dict` or an `argparse.Namespace` crosses into domain
code. The parse checks every invariant the domain relies on, reports every
problem it finds at once, and runs before any side effect. Structured data is
parsed with Pydantic. Command-line arguments are parsed by a library whose
result the type checker knows, or by `argparse` with its `Namespace` read only
inside that function.

**Results are returned, not raised.**
An expected failure is returned as a sum type, not raised: either a generic
`Ok[T] | Err[E]` made of two frozen dataclasses, or a union of named outcomes such as
`AlreadyRestored | NothingSaved | Restore`, matched exhaustively like any other union.
The `Ok`/`Err` pair is defined once in the project, in about 15 lines, rather than taken
from a library. `try/except` is reserved for system boundaries and truly unexpected
errors.

**An expected failure ends the program with a sentence a person can act on, not a traceback.**
Missing input, absent state and a precondition that does not hold each end the run with a message
that says what to do next and a non-zero exit status. The failure travels as a returned outcome up
to the entry point, which is the one place that turns it into that message and exit, with
`SystemExit("…")` as the usual form. A traceback is kept for the genuinely unexpected, where the
stack is what the reader needs.

**Code that changes a developer's own machine can be undone, and refuses to run when it could not
be.**
Caches, databases, config and checkouts on the machine the code runs on are backed up before they
are written, and the inverse operation exists. A run refuses rather than overwrite a backup that an
earlier run left behind, because that backup may be the only copy of the developer's state.

**A script's module docstring says what the script does and how to run it.**
It is the first documentation a reader meets, and `--help` is built from it, so a reader can tell
from those lines whether this is the tool they want.

**Import architecture is enforced by `import-linter` in CI, wherever there is more than one module
to layer.**
A `.importlinter` contract defines which packages may import from which others,
mirroring the intended layering (e.g. `api → domain`, never `domain → api`).
`lint-imports` runs in CI. A violation fails the build. A single-file script has nothing to layer,
so it has no contract.

## Should

**`beartype` is enabled in tests.**
`beartype` adds runtime type enforcement that catches what `ty` misses at the
boundary between typed and untyped code. Enable it in the test suite, not in
production.

**A module run with `python -m` names its logger explicitly.**
Run that way, the module's `__name__` is `"__main__"`, so `logging.getLogger(__name__)` creates a
logger outside the package whose logging configuration was meant to cover it. Its records then fall
through to the root logger's level and can be dropped with no error. In one work repo,
a migrate command's outcome line vanished this way, and only a test that ran the module as a
subprocess caught it. `logging.getLogger("package.module")` keeps the name the same whether the
module is imported or run.

**A script outside a project is one file run by `uv`, with its dependencies declared inline.**
PEP 723 metadata at the top and a `#!/usr/bin/env -S uv run --script` shebang leave no virtualenv
to activate, no install step and no doubt about which interpreter the script wants. A script in a
repo with a `pyproject.toml` runs through that project instead, so it can import the project's
shared code, such as its `Ok`/`Err` pair.

**Return types are not quoted.**
Add `from __future__ import annotations` at the top of any file targeting
Python < 3.14 rather than quoting return type annotations. Quoted annotations
are harder to read and unnecessary with the future import.

## In scope

- Every `.py` file, scripts included

## Out of scope

- Auto-generated .py files
- Vendored Python code not maintained in this repo
