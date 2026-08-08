# Code Readability

Code is readable when names communicate intent, units do one thing, and the
structure of the code matches the complexity of the problem it solves.

## Must

**Names use domain vocabulary and reflect intent.**
Names say what a thing is or does, not how it works or where it came from.
The vocabulary comes from the domain, not implementation concerns —
`connection` not `conn`, `request_timeout` not `max`, `publish` not `handle`.
Implementation vocabulary — process, handle, manage, data, info, util —
signals a gap between code and domain. Names are never abbreviated unless
the abbreviated form is the established domain term.

**Dead code is absent.**
Unused imports, variables, functions, and commented-out code don't exist.
Remnants from exploration or abandoned approaches are removed before merging.

**Work is finished before it ships.**
Incomplete implementations, known hacks, and deferred cleanup don't ship as
permanent fixtures. Code is easier to change while the context is loaded.
Debt deferred compounds — do it right while it's hot.

**Abstractions earn their place.**
Every abstraction is used in more than one place or makes a single complex
thing significantly clearer. Helpers that exist for one call site are inlined.
Wrappers that add no clarity are removed.

**Each unit has one responsibility.**
Functions do one thing. Types represent one concept. Functions and types whose
purpose requires a conjunction ("and", "or") to describe are split.

## Should

**Files are under 500 lines and represent discrete domain concepts.**
Files longer than 500 lines are split at natural seams. Agents silently
truncate long files, creating blind spots that lead to false conclusions. File
names enumerate discrete domain concepts and are grouped under subfolders
that enumerate higher-level concepts whenever that helps the file system
read like a catalogue of the codebase's domain entities and behaviours.

**Functions are small enough to reason about.**
Blocks nested more than two levels deep are extracted to named functions.
Predicates and transformations passed to higher-order functions are extracted
to named functions when their bodies can't be understood at a glance.
Functions that require scrolling to read are split at natural seams.

**Boolean parameters are not used to select behaviour.**
A function that accepts a boolean to switch between two modes is two functions.
A parameter that is always `true` or always `false` at its call sites is a
design smell. Where multiple options are needed, a named options type or enum
is used instead.

**Logic is not clever.**
When a simpler, more direct expression achieves the same result, it is used.
Cleverness that requires a comment to explain is rewritten.

**Values are immutable unless mutation is necessary.**
Variables and fields are immutable by default. Functions return new values
rather than modifying inputs in place. Mutation that is required is explicit
and visible at the call site.

**Complexity matches the problem.**
The solution is not over-engineered (configurable where hardcoded suffices,
generalized for one case, layered where flat would do) or under-engineered
(everything in one place, no meaningful separation).

**Existing patterns are followed.**
The codebase has established ways of solving common problems. New code follows
them unless there is a deliberate reason to diverge.

**Data flows in one direction.**
State transformations move forward through the call stack. Callbacks, circular
references, and shared mutable state are avoided where a simple pipeline
would do.

## Consider

**Related names sort by most significant word.**
When a concept has qualifiers (unit, bound, direction), the concept leads:
`connection_count_max` rather than `max_connection_count`. Related names
align visually and sort meaningfully when listed together.

**Magic values are named.**
Literal numbers and strings that carry meaning are extracted to named
constants. A reader understands what a value represents without searching
for its origin.

## In scope

- All non-generated, non-vendored source files

## Out of scope

- Generated code
- Vendored code
- Test fixtures with intentionally repetitive structure
- One-off scripts explicitly scoped to a single use
