# Design

Code is well-designed when its internal structure matches the complexity of the
problem it solves, and similar problems within a codebase are solved the same way.

## Must

**Abstractions earn their place.**
Every abstraction is used in more than one place or makes a single complex thing
significantly clearer. Helpers that exist for one call site are inlined. Wrappers
that add no clarity are removed.

**Each unit has one responsibility.**
Functions do one thing. Types represent one concept. When a function or type
covers multiple concerns, it is split at the seam between them.

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

## Consider

**Unrelated changes are in separate commits.**
Refactoring, bug fixes, and feature work mixed into a single diff make intent
harder to review and history harder to bisect.
