# Assertions

Assertions are runtime invariant checks — distinct from tests, which verify
behavior before deployment, and from error handling, which manages expected
failures. An assertion failure is evidence of a programmer error, a violation
of something that must always be true.

## Must

**Invariants are asserted at runtime.**
Conditions that must always hold — preconditions, postconditions, internal
state — are asserted where they apply, not only in tests. An assertion that
fires in production catches a class of bugs that tests alone cannot.

**Assertions cover both the expected and the unexpected.**
The positive space (what must be true) and the negative space (what must never
be true) are both asserted. A function that must never receive null asserts it.
A value that must always be positive asserts it. The contract and its breach
are both stated.

## Should

**Arguments and return values are asserted.**
Function arguments are asserted to satisfy preconditions before use. Return
values are asserted to satisfy postconditions before returning. Silent
assumptions become audible failures.

**Assertion failures halt the program.**
When an assertion fails, the program stops rather than continuing in an unknown
state. An assertion is not a recoverable error — it is a programmer error that
must be fixed.

## Consider

**Assertions multiply the value of fuzzing.**
Because assertions check invariants on every execution path, fuzz inputs that
reach unexpected states trigger assertion failures that uncover bugs invisible
to deterministic tests.

## When scanning

**Surfaces:** all source files, with emphasis on functions operating on validated types, state machines, and complex invariants.

**False positives to skip:** test assertion helpers (e.g. `assert_eq!`, `pytest.raises`) — these are test infrastructure, not runtime invariant checks.
