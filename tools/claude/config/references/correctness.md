# Correctness

Code is correct when it faithfully implements its stated intent across all
inputs, states, and callers.

## Must

**Logic covers all meaningful branches.**
Conditionals, loop bounds, and comparisons are exact. Off-by-one errors don't
exist. Every reachable branch is handled.

**Edge cases are handled.**
Empty collections, null/None/zero, single-element inputs, and boundary values
produce defined behavior. Edge-case behavior matches general-case behavior
unless the difference is deliberate.

**Errors propagate consistently.**
Errors are surfaced the same way surrounding code surfaces them. Errors are not
swallowed silently unless the codebase establishes that as a deliberate pattern.

**Existing solutions are used.**
When the codebase already solves this problem — a utility, a pattern, a shared
abstraction — that solution is used rather than reimplemented.

**Implementation is complete and finished.**
Every stated outcome exists in the code. There are no half-implemented paths,
silently missing behaviors, known hacks, or deferred cleanup. Incomplete work
and shortcuts don't ship as permanent fixtures — they compound and they're
easiest to address while the context is still loaded.

## Should

**Existing callers and data are unaffected.**
Changes don't break existing call sites or corrupt existing data unless the
breakage is intentional, documented, and coordinated.

## Consider

**Implicit assumptions are explicit.**
If the code assumes something about its inputs or environment that types and
validation don't enforce, that assumption is either enforced or noted at the
call site.

## In scope

- Complex branching logic, parsers, and state machines
- Boundary value handling

## Out of scope

- Code explicitly marked as experimental or draft
- Code gated behind a flag that disables it in production
