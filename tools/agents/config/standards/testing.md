# Testing

Tests are trustworthy when they fail for the right reasons, pass for the right
reasons, and cover the behaviors that matter most.

## Must

**Tests verify behavior, not implementation.**
Assertions are on outcomes observable by a caller — return values, side
effects, error types. Internal state, private methods, and call counts are
not asserted unless they are the observable contract.

**Passing tests are meaningful.**
A test that always passes regardless of what the code does provides no value.
Every assertion can fail, and would fail if the behavior it covers were broken.
A test written after the code it covers has not demonstrated that by passing, so
it is confirmed against a deliberate break — a condition inverted, a term
dropped, a constant returned — and the confirmation is that the right test fails
and names the right thing.

**Critical paths have test coverage.**
Authentication, authorization, payment flows, data integrity operations, and
error handling paths are tested. The absence of tests here is a defect.

## Should

**Test names describe behavior in domain terms.**
A test name is documentation — it states what the system does in language the
domain recognizes. `subscription_expires_after_trial_period` is domain
documentation. `process_user_data` is not. A failing test name alone should
tell a reader what broke without reading the test body.

**Each test covers one behavior.**
A test has one reason to fail. Multiple unrelated assertions in a single test
obscure which behavior broke.

**Test inputs span the meaningful space.**
Happy path, empty input, boundary values, and error conditions are all
represented. Parametrization is used when the same behavior holds across a
range of inputs.

**A generator produces the inputs that exercise the behaviour under test.**
A property test whose generator rarely reaches the branch in question passes
identically against correct and broken code, while reading as the strongest test
in the suite. Generators are shaped toward the region that matters — the long
input, the empty one, the one dense with separators — and the shaping is
confirmed the same way as any other test, by watching it fail against a
deliberate break.

**Tests are independent.**
No test depends on the execution order of other tests or on state left behind
by a previous test. Each test sets up what it needs and cleans up after itself.

**Test code is held to the same standard as production code.**
Duplicated setup is extracted to fixtures or helpers. Names are as descriptive
as in production code. Dead test code is removed.

**Conditions that can be asserted at runtime are asserted as well as tested.**
A test covers the inputs its author imagined; an assertion covers the inputs
production supplies. A condition that must always hold is asserted at its site
and tested for the cases worth naming, rather than left to tests alone, which
see only synthetic data. Which conditions are assertions, which belong in
validation at an I/O boundary, and which are returned as errors is set out in
`correctness.md`.

**Mocks are used only at system boundaries.**
Real objects are used wherever possible. Mocks are reserved for external APIs,
time, randomness, and other true system boundaries. Excessive mocking
disconnects tests from real behavior and masks integration failures.

For HTTP API boundaries specifically, a fake HTTP server is preferred over a
trait-based mock — it exercises URL construction, headers, and serialization,
not just call presence.

Some behaviour cannot be exercised in-process at all. Anything that depends on
a connection staying open — streaming, timeouts, backpressure, reconnection,
a stall that never raises an error — needs a real server and a real connection,
because an in-process request helper completes immediately by construction. A
test that appears to cover a stream but never holds one open passes for the
wrong reason.

**The urge to mock a non-boundary component is a signal that logic is in the wrong layer.**
When testing requires mocking something that isn't a true system boundary, the logic
being tested belongs one layer closer to the pure core. Moving it there makes it
directly testable without mocks and reveals the correct architectural boundary.

**More powerful techniques are used where they fit.**
Property-based testing applies when a behavior holds for a large or unbounded
input space. Snapshot testing applies for serialized structures or rendered
output. Mutation testing applies when confidence in a suite's sensitivity is
low. Generated-input techniques compound with assertions in the code under
test: every generated case exercises those assertions too, so one run covers
the properties the test states plus every invariant the implementation
asserts. Code that asserts its invariants is worth more generator effort than
code that does not.

## Consider

**Flakiness risk is minimized.**
Tests that depend on timing, execution order, or external state are identified
and either fixed or explicitly marked. Async operations are awaited, not raced.

**Plain helpers are preferred over framework abstractions.**
Test setup lives in plain functions unless the framework provides something
those functions cannot — lifecycle hooks, shared fixtures with teardown. The
simpler form is chosen by default.

## In scope

- Files containing test functions or classes
- Files in test directories

## Out of scope

- Test utility helpers and fixture factories (not themselves subject to behavioral coverage requirements)
