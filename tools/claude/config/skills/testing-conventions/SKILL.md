---
name: testing-conventions
description: Test design patterns and style guide (when alternate patterns are not specified at the project level)
---

## Unit testing patterns

- Consider a property-based vs example-based vs snapshot-based test and choose the best fit
- For example-based tests, when testing multiple inputs that should produce the same outcome (e.g. various forms of "empty"), prefer one test that iterates over multiple input scenarios (in whatever way is most idiomatic) over a separate test function for every input-output scenario

### Libraries

- Python: use `pytest` for unit tests
- Python: use `hypothesis` for property-based tests
- Python: use `inline-snapshot` for snapshot-based tests
- JS/TS: use `vitest` for unit tests (unless `jest` is already installed in the project)
- JS/TS: use `fast-check` for property-based tests
- React: use `@testing-library/react` for component tests
