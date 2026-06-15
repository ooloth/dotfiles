# Code Quality

Code quality is local: names, size, and the absence of noise. A file has high
code quality when any expression or function can be understood in isolation.

## Must

**Dead code is absent.**
Unused imports, variables, functions, and commented-out code don't exist.
Remnants from exploration or abandoned approaches are removed before merging.

**Naming reflects intent.**
Names say what a thing is or does, not how it works or where it came from.
A reader shouldn't need to trace an implementation to understand a call site.
Names are never abbreviated — `connection` not `conn`, `maximum` not `max`,
unless the abbreviated form is the established domain term.

## Should

**Files are under 500 lines and represent discrete domain concepts.**
Files longer than 500 lines are split at natural seams. Agents silently truncate long files,
creating blind spots that lead to false conclusions. And humans have a hard time understanding them.
File names enumerate discrete domain concepts and are grouped under subfolders that enumerate
higher level concepts whenever that helps the file system read like a catalogue of the codebase's
domain entities and logical behaviours and the boundaries between them.

**Functions are small enough to reason about.**
Blocks nested more than two levels deep are extracted to named functions. Predicates and
transformations passed to higher-order functions are extracted to named functions when their
bodies can't be understood at a glance. Functions that require scrolling to read are split at
natural seams.

**Boolean parameters are not used to select behaviour.**
A function that accepts a boolean to switch between two modes is two functions.
A parameter that is always `true` or always `false` at its call sites is a
design smell. Where multiple options are needed, a named options type or enum
is used instead.

**Logic is not clever.**
When a simpler, more direct expression achieves the same result, it is used.
Cleverness that requires a comment to explain is rewritten.

**Values are immutable unless mutation is necessary.**
Variables and fields are immutable by default. Functions return new values rather
than modifying inputs in place. Mutation that is required is explicit and visible
at the call site.

## Consider

**Related names sort by most significant word.**
When a concept has qualifiers (unit, bound, direction), the concept leads:
`connection_count_max` rather than `max_connection_count`. Related names
align visually and sort meaningfully when listed together.

**Magic values are named.**
Literal numbers and strings that carry meaning are extracted to named constants.
A reader understands what a value represents without searching for its origin.

## In scope

- All non-generated, non-vendored source files

## Out of scope

- Generated code
- Vendored code
- Test fixtures with intentionally repetitive structure
