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

**Runtime invariants are asserted, not only tested.**
Conditions that must always hold — preconditions on inputs, postconditions on
outputs, internal state constraints — are asserted where they apply, not only
in tests. Both what must be true and what must never be true are stated. An
assertion that fires in production catches programmer errors that tests alone
cannot.

**Assertions are split so a failure names the exact violation.**
One condition per assertion. `assert(a && b)` reports that something broke;
`assert(a)` followed by `assert(b)` reports which. Where a contract spans a call
boundary it is asserted on both sides — the caller checks what it promises, the
callee checks what it requires — so a disagreement about the contract surfaces
as well as a violation of it.

**Loops and recursion have fixed upper bounds.**
Every loop has a bound a reader can determine without running it, and recursion
either has a proven depth limit or is written as iteration. Queues, buffers, and
accumulating collections have an explicit cap. An unbounded loop turns a logic
bug into a hang and an unbounded buffer turns one into an outage — the two
failure modes hardest to diagnose from outside the process.

**Behaviour is deterministic given the same inputs.**
The same inputs produce the same outputs and the same sequence of effects.
Clocks, randomness, iteration order over unordered collections, and scheduling
are injected or seeded rather than reached for directly. A bug that reproduces
costs an order of magnitude less to fix than one that doesn't, and replaying a
failure is only possible if the system was deterministic to begin with.

## Should

**Existing callers and data are unaffected.**
Changes don't break existing call sites or corrupt existing data unless the
breakage is intentional, documented, and coordinated.

**`assert` is for programmer errors; errors are returned for environmental failures.**
The discriminator: could this condition occur because of something outside the
code — absent config, malformed input, a failed network call? If yes, return
an error. If only a bug within the codebase could trigger it, assert it.
Assertion failures halt; they are not caught and recovered from.

## Consider

**Assertions multiply the value of fuzzing.**
Because assertions check invariants on every execution path, fuzz inputs that
reach unexpected states trigger assertion failures — uncovering bugs invisible
to deterministic tests.

## In scope

- All non-generated, non-vendored source files

## Out of scope

- Code explicitly marked as experimental or draft
- Code gated behind a flag that disables it in production
