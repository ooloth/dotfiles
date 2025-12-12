## Libraries

- In Python, use `pytest` for unit tests
- In JS/TS, use `vitest` (unless `jest` is already installed in the project)

## Test concisely

### Property-based testing

- Consider testing properties/characteristics/invariants (with auto-generated example inputs) rather only testing a handful of specific input/output examples
- Would that be more thorough way to build confidence in how a given scenario is handled?
- Would that help maintainers better understand the fundamental behaviour of that code?
- In Python, use `hypothesis` for this
- In JS/TS, use `fast-check`

### Iterative example-based testing

- When testing multiple cases with the same outcome (e.g. handles all "empty" input varieties is X way), prefer a single test case that iterates over multiple input-output scenarios over one test case per scenario
