# Testing

Tests are how a team knows the code still does what it is for. At their maximum:

- **Safety:** the suite fails whenever a behavior it covers breaks and passes only when it holds, so
  a passing run is evidence.
- **Performance:** the suite gives that answer as fast as the work allows. Tests run in parallel,
  wait on events rather than the clock, and build what never changes once.
- **Experience:** a failing test's name says what broke, and a reader learns what the system does
  from the test names alone.

## Must

**Tests verify behavior, not implementation.**
Assertions are on outcomes observable by a caller, such as a return value or an error type.
Internals, such as private methods or call counts, are not asserted unless they are the observable
contract. A call made across a system boundary, such as a charge sent to a payment provider, is part
of the observable contract, so asserting it is allowed.

**Passing tests are meaningful.**
A test that always passes regardless of what the code does provides no value. Every assertion can
fail, and would fail if the behavior it covers were broken. Passing alone doesn't show that a test
written after its code can fail. So the test is run against a deliberate break, such as an inverted
condition, and the right test fails and names the right thing. The change records the break and the
failure. The recorded break is in the code the test's name or docstring says it guards. A setup that
never produces the condition the code handles passes whatever the code does. Many setups never
produce it: a database session shared across requests, for example, can show writes that were never
committed. A property the types make impossible needs no test of its own, and a deliberate break of
it is confirmed when the type checker rejects it. An assertion does not replace a test: a property
an assertion guards is tested too, and generated inputs that drive the code until the assertion
fires are among the strongest of those tests.

**A check whose selection matches nothing fails, unless its input is legitimately empty where it
runs.** Many checks, such as a test runner or a linter aimed at a glob, report success when their
selection matches nothing, and the success looks the same as a real pass. So an empty selection is a
failure: the tool's own signal is used where it has one, such as a test runner's exit code for
collecting nothing, and a guard runs ahead of the tool where it has none.

This is about a selection that came up empty by mistake. A check whose input is
legitimately empty in some environment, such as a machine with nothing
configured, says it skipped and why instead of failing.

**Critical paths have test coverage.**
Paths where a failure does harm, such as authentication, payments or data integrity, are tested. The
absence of tests here is a defect. Coverage includes each way the path can fail, not only its
success.

**A change that deletes or replaces tests keeps each property they checked, or says why it drops
it.**
A replacement that looks broader can still miss a case the old test caught, and nothing fails to
show it, because the test that would have failed is gone. So for each removed test, assertion or
expected-value helper, the change names the test that now checks the same property for the same
inputs, or states in the commit or PR why the property no longer needs checking. "The new tests
replace the old ones" is not a reason; one property at a time is.

## Should

**Test names describe behavior in domain terms.**
A test name is documentation — it states what the system does in language the domain recognizes.
`subscription_expires_after_trial_period` is domain documentation. `process_user_data` is not. A
failing test's name alone tells a reader what broke without reading the test body.

**Each test covers one behavior.**
A test has one reason to fail. Multiple unrelated assertions in a single test obscure which behavior
broke.

**An expectation is written separately from the code it checks.**
This covers what the Must on meaningful tests can miss: an expectation computed the same way the
code computes it, such as a copied formula, can still fail when the code changes, yet agrees with
any mistake the two share. A test that reads what to expect from the code under test, such as a
route's declared roles or the constants a function compares against, passes whatever that code does,
because the expectation moves with it. The expected values are literals taken from what the behavior
is for, compared with what the code does. Where they are too many to write one by one, they still go
in a table written that way rather than generated from the code's answers, since a generated table
copies today's mistakes into the expectation. A table drafted with help, from an agent or a
document, counts only once each row has been checked against a source the code does not read. A
snapshot or golden-file test, which exists to detect change rather than to define correct output, is
the exception, and it still meets the Must on meaningful tests because it fails whenever the output
changes.

**A check that expects an access refusal sends a request that passes validation, so the refusal
comes from the access check and not from the parser.**
Where a framework validates a request's body before the handler runs, an access check inside the
handler runs only after that. A test that sends a placeholder body, such as `{}`, gets the
framework's validation error, and a test that accepts any refusal passes without the access check
ever running. The route could admit the caller with a real body and the test would not notice. So
each request carries a body that passes the schema, the test accepts only the access check's own
answers, such as 403 or a 404 for a row the caller may not see, and a new route that takes a body
fails until it has one.

**A test of a check that runs before every handler sends its request through the whole
application.**
Middleware, request hooks and other checks the application runs for every request are registered
on the application, not on the handler. A test that mounts one handler on a bare application, or
calls the handler function directly, never runs them, so it passes whether the check exists or not.
Such a test sends its request through the application as it is built for production, with only the
boundaries replaced, such as the identity provider and the data store. It is paired with a request
the check allows reaching the same handler, so a check that refuses everything does not pass as one
that refuses correctly. Where every route should be covered, the cases come from the application's
own list of routes, so a route added later is tested with no new test.

**Tests span every dimension the behavior varies along.**
Inputs are one dimension: happy path, empty input, boundary values and error conditions are all
represented. Other dimensions include who is acting (a role or account type), how the system is
configured (each state of a flag the code reads), and when the data was written (before the change,
or by an older version). Each value of each dimension is covered, and so is each combination the
code makes interact. A combination left out is named as not covered. Parametrization is used when
the same behavior holds across a range of values.

**A generator produces the inputs that exercise the behaviour under test.**
A property test whose generator rarely reaches the branch in question passes identically against
correct and broken code, while reading as the strongest test in the suite. Generators are shaped
toward the region that matters, such as the long input or the empty one, and the change records the
deliberate break the shaped generator failed against.

**Tests are independent.**
No test depends on the execution order of other tests or on state left behind by a previous test.
Each test sets up the state it changes and cleans up after itself, and parts that never change are
shared read-only, as the next claim describes.

**Fixture parts that never change are built once and shared read-only, and parts a test changes are
built fresh for each test.** Parts that never change, such as a stub executable with fixed content,
are written once per test class or module, in a folder made read-only so that no test can change
what another one runs. Everything a test writes to, such as its home directory, logs and response
tables, stays in that test's own temporary directory. Rebuilding the unchanging parts for every
example multiplies a property test's cost by its example count.

**A test that checks concurrent work ran together observes the overlap, not the elapsed time.**
Each concurrent unit records that it started, then waits, up to a bound of its own, until the others
have started too, so the test passes only when they really ran together. A bound on the total run
time can fail on a loaded machine while the code is correct, because a busy machine can slow both
runs by more than the gap between them. The change records the test failing against a version of the
code changed to run the units one at a time.

**A test waits for the event it needs, not for a fixed time.**
A fixed sleep can be too short on a loaded machine and is longer than needed everywhere else, so the
test is both flaky and slow. The test waits on the signal that the work is done, such as a message,
a file or a state change, with a bound of its own.

**Test code is held to the same standard as production code.**
Duplicated setup is extracted to fixtures or helpers. Names are as descriptive as in production
code. Dead test code is removed.


**Mocks are used only at system boundaries.**
Real objects are used wherever possible. Mocks are reserved for true system boundaries, such as
external APIs, time and randomness. Excessive mocking disconnects tests from real behavior and masks
integration failures.

For HTTP API boundaries specifically, a fake HTTP server is preferred over an interface-based mock,
because it exercises what the request carries, such as its URL, headers and body, not just that a
call happened.

Some behaviour cannot be exercised in-process at all. Anything that depends on a connection staying
open, such as streaming, a timeout or a stall that never raises an error, needs a real server and a
real connection, because an in-process request helper can return the whole response without ever
holding a connection open. A test that appears to cover a stream but never holds one open passes for
the wrong reason.

**Logic a test can reach only by mocking a non-boundary component sits in the wrong layer.**
When testing requires mocking something that isn't a true system boundary, the logic being tested
belongs one layer closer to the pure core. Moving it there makes it directly testable without mocks
and reveals the correct architectural boundary.

**Testing techniques suited to the behavior are used where they fit.**
Such techniques include property-based testing for a large or unbounded input space, snapshot
testing for serialized or rendered output, and mutation testing where the suite's sensitivity is in
doubt. Generated inputs also exercise the assertions in the code under test: every generated case
that reaches one checks it, so one run covers the properties the test states and the invariants the
code asserts along its path. Code that asserts its invariants is worth more generator effort than
code that does not.

**Code that reads another system's payload is run against a payload that system actually sent, not
only its documented example.** A vendor's example is written separately from the code that sends the
payload, and the two drift. A vendor's example and its real deliveries can differ, such as in a
field's spelling or casing. A transform, parser or mapping tested only against the example passes,
then reads nothing from the field that differs, and a fallback value hides the miss. So before its
output is relied on, the code is run on a real payload, captured from the receiving side or a log,
and the change records which one. That payload is kept beside the code's tests wherever it holds no
secrets or personal data.

**A test of what a log line holds reads the line through the formatter the app writes it with.**
Where a test runner captures log records and formats them with its own formatter, whatever the app's
formatter does, such as redacting a value, never reaches the captured record. A test that reads the
capture can pass while the app writes a value it means to keep out, and fail when the app's
formatter correctly removes one. So the test formats each captured record with the app's formatter,
or reads what the running process wrote.

## Consider

**Flakiness risk is minimized.**
Tests that depend on something outside their control, such as timing or execution order, are
identified and either fixed or explicitly marked. Async operations are awaited, not raced.

**Plain helpers are preferred over framework abstractions.**
Test setup lives in plain functions unless the framework provides something those functions cannot,
such as lifecycle hooks. The simpler form is chosen by default.

## In scope

- Files containing test functions or classes
- Files in test directories

## Out of scope

- Test utility helpers and fixture factories (not themselves subject to behavioral coverage
  requirements)
