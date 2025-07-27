---
description: Fix failing tests and improve test coverage
---

## Systematic Test Fixing Process

### Phase 0: Planning & Strategy Assessment
**Before fixing test issues, confirm approach:**
- **Have you planned your test fixing strategy?** If not, start here:
  1. **Quick assessment** - Are these isolated failures or systematic issues?
  2. **Consider alternatives**:
     - Direct fix (simple test logic errors)
     - Update tests (behavior changed legitimately)
     - Improve test design (flaky/brittle tests)
     - Add missing coverage (gaps in test scenarios)
     - Test infrastructure (environment/setup issues)
  3. **Choose optimal approach** based on:
     - Whether code behavior changed intentionally
     - Test quality and maintainability
     - Urgency of getting tests passing
     - Root cause of failures
  4. **Plan test strategy** - How to prevent similar failures?

### Phase 1: Test Analysis
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