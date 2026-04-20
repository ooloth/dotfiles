---
name: conventions-for-tests
description: Test design patterns and style guide (when alternate patterns are not specified at the project level). TRIGGER when writing, editing, or reviewing test files.
model: haiku
effort: low
paths:
  - '**/test_*.py'
  - '**/*_test.py'
  - '**/*.test.ts'
  - '**/*.spec.ts'
  - '**/*.test.tsx'
  - '**/*.spec.tsx'
  - '**/*.test.js'
  - '**/*.spec.js'
---

## Testing approaches

### Unit tests (glass box)

- Are any useful example-based unit tests missing?
- Are any useful property-based tests missing?
- Are any useful snapshot-based tests missing?
- Do mutation tests prove that the unit test coverage is complete?
- Are any useful integration tests missing?

### Integration tests

- Are any tests that would detect breaking changes in external API contracts missing?

### Real world tests (black box, e2e, workload)

- Are any useful outside-in e2e tests of the system's invariants based on its observable outputs missing?
- Are any observability signals that would unlock better black box testing missing?

## Unit testing patterns

- Consider property-based vs example-based vs snapshot-based tests and choose the best fit for each case
- For example-based tests, when testing multiple inputs that should produce the same outcome (e.g. various forms of "empty"), prefer one test that iterates over multiple input scenarios (in whatever way is most idiomatic) over a separate test function for every input-output scenario
- Prefer the simple readability of normal helper functions over test framework equivalents (fixtures, etc) whenever the latter doesn't add real value

### Libraries

- Python: use `pytest` for unit tests
- Python: use `hypothesis` for property-based tests
- Python: use `inline-snapshot` for snapshot-based tests
- Python: use `mutmut` for mutation tests
- JS/TS: use `vitest` for unit tests (unless `jest` is already installed in the project)
- JS/TS: use `fast-check` for property-based tests
- React: use `@testing-library/react` for component tests

Apply these conventions to the current task.
