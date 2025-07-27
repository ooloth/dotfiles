---
description: Fix failing tests and improve test coverage
---

## Systematic Test Fixing Process

1. **Identify failures** - Run tests and capture error messages
2. **Analyze root cause** - Determine if it's test issue or code issue
3. **Categorize problems**:
   - Flaky tests (environment/timing dependent)
   - Broken assertions (code behavior changed)
   - Setup/teardown issues
   - Missing coverage gaps
4. **Fix systematically** - Address root causes, not symptoms
5. **Verify fixes** - Run tests multiple times to ensure stability
6. **Improve test quality** - Refactor for clarity and maintainability

### Common Test Issues:
- Timing dependencies → Add proper waits or mocks
- Environment dependencies → Use test fixtures
- Brittle selectors → Use data attributes
- Over-mocking → Test real behavior when possible
- Under-specified assertions → Be explicit about expectations

Test issue: $ARGUMENTS