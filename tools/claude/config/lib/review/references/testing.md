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

**Critical paths have test coverage.**
Authentication, authorization, payment flows, data integrity operations, and
error handling paths are tested. The absence of tests here is a defect.

## Should

**Each test covers one behavior.**
A test has one reason to fail. Multiple unrelated assertions in a single test
obscure which behavior broke.

**Test inputs span the meaningful space.**
Happy path, empty input, boundary values, and error conditions are all
represented. Parametrization is used when the same behavior holds across a
range of inputs.

**Tests are independent.**
No test depends on the execution order of other tests or on state left behind
by a previous test. Each test sets up what it needs and cleans up after itself.

**Test code is held to the same standard as production code.**
Duplicated setup is extracted to fixtures or helpers. Names are as descriptive
as in production code. Dead test code is removed.

**Mocks are used only at system boundaries.**
Real objects are used wherever possible. Mocks are reserved for external APIs,
time, randomness, and other true system boundaries. Excessive mocking
disconnects tests from real behavior and masks integration failures.

## Consider

**More powerful techniques are used where they fit.**
Property-based testing applies when a behavior holds for a large or unbounded
input space. Snapshot testing applies for serialized structures or rendered
output. Mutation testing applies when confidence in a suite's sensitivity is
low.

**Flakiness risk is minimized.**
Tests that depend on timing, execution order, or external state are identified
and either fixed or explicitly marked. Async operations are awaited, not raced.

**Plain helpers are preferred over framework abstractions.**
Test setup lives in plain functions unless the framework provides something
those functions cannot — lifecycle hooks, shared fixtures with teardown. The
simpler form is chosen by default.
