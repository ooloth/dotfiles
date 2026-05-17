# Design

Code is well-designed when its internal structure matches the complexity of the
problem it solves, and similar problems within a codebase are solved the same way.

## Must

**Work is finished before it ships.**
Incomplete implementations, known hacks, and deferred cleanup ship as
permanent fixtures. Code is easier to change while the context is loaded.
Debt deferred compounds — do it right while it's hot.

**Abstractions earn their place.**
Every abstraction is used in more than one place or makes a single complex thing
significantly clearer. Helpers that exist for one call site are inlined. Wrappers
that add no clarity are removed.

**Each unit has one responsibility.**
Functions do one thing. Types represent one concept. Functions and types whose
purpose requires a conjunction ("and", "or") to describe are split into
separate units.

## Should

**Complexity matches the problem.**
The solution is not over-engineered (configurable where hardcoded suffices,
generalized for one case, layered where flat would do) or under-engineered
(everything in one place, no meaningful separation).

**Existing patterns are followed.**
The codebase has established ways of solving common problems. New code follows
them unless there is a deliberate reason to diverge.

**Data flows in one direction.**
State transformations move forward through the call stack. Callbacks, circular
references, and shared mutable state are avoided where a simple pipeline would do.

## In scope

- All non-generated, non-vendored source files

## Out of scope

- Test code that duplicates setup intentionally for test isolation
- One-off scripts explicitly scoped to a single use

