# Tests

## Ideal state

### Coverage across testing approaches

- Unit tests (glass box): example-based, property-based, snapshot-based, mutation-tested
- Integration tests: detect breaking changes in external API contracts
- E2e tests (black box): outside-in tests of the system's invariants based on observable outputs

### Unit testing patterns

- Choose property-based vs example-based vs snapshot-based per case
- For multiple inputs producing the same outcome, prefer one parameterised test over a separate function per scenario
- Prefer plain helper functions over test framework abstractions (fixtures, etc.) unless the framework adds real value

### Libraries

- Python: `pytest` (unit), `hypothesis` (property-based), `inline-snapshot` (snapshot), `mutmut` (mutation)
- JS/TS: `vitest` (unit, unless `jest` is already installed), `fast-check` (property-based)
- React: `@testing-library/react` (component tests)

## Common failure modes

- Untested code paths
- Excessive mocking making tests brittle or disconnected from real behaviour
- Missing testing approaches that would add confidence (e.g. no property-based tests, no e2e tests)
- Tests that are hard to understand — duplicated setup, one function per input scenario that could be parameterised
- Tests organised around implementation details rather than observable behaviour
