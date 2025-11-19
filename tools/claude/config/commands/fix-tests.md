---
description: Comprehensive test improvement, creation, and coverage enhancement
---

## Comprehensive Test Enhancement Process

### Phase 0: Planning & Strategy Assessment

**Before working on tests, confirm approach:**

- **Have you planned your test strategy?** If not, start here:
  1. **Quick assessment** - Fixing failing tests, adding coverage, or designing new tests?
  2. **Consider alternatives**:
     - Direct fix (simple test logic errors)
     - Update tests (behavior changed legitimately)
     - Improve test design (flaky/brittle tests)
     - Add missing coverage (gaps in test scenarios)
     - Create comprehensive test suite (new functionality)
     - Test infrastructure improvements (setup, tools, CI)
  3. **Choose optimal approach** based on:
     - Current test coverage and quality
     - Whether code behavior changed intentionally
     - Risk level of untested code
     - Team testing standards and tools
  4. **Plan test architecture** - How to prevent issues and ensure maintainability?

### Phase 1: Test Analysis & Assessment

#### 🔍 **Test Coverage Analysis**

1. **Run coverage reports** - Identify gaps in line, branch, and function coverage
2. **Analyze test quality** - Meaningful assertions, edge cases, error scenarios
3. **Identify missing test types** - Unit, integration, end-to-end coverage
4. **Assess test architecture** - Organization, maintainability, speed

#### 🐛 **Failure Analysis** (if tests are failing)

1. **Identify failures** - Run tests and capture error messages
2. **Check CI failures** (recursionpharma repos only):
   - If tests pass locally but fail in CI, use the `inspect-codefresh-failure` skill
   - It will analyze Codefresh logs and identify environment differences, missing dependencies, or timing issues
3. **Analyze root cause** - Test issue vs code behavior change vs environment difference
4. **Categorize problems**:
   - Flaky tests (environment/timing dependent)
   - Broken assertions (code behavior changed legitimately)
   - Setup/teardown issues
   - Missing coverage for new functionality
   - CI-specific failures (environment, dependencies, timing)

### Phase 2: Test Design & Creation

#### 📋 **Test Design Strategy**

1. **Identify test scenarios** - Happy paths, edge cases, error conditions
2. **Choose test types** - Unit tests for logic, integration tests for interactions
3. **Design test structure** - Arrange-Act-Assert pattern, clear naming
4. **Plan test data** - Fixtures, factories, mocks vs real data

#### ✅ **Test Implementation Principles**

- **Test behavior, not implementation** - Focus on what code does
- **One assertion per test** when possible for clarity
- **Descriptive test names** - Explain expected behavior clearly
- **Independent tests** - No dependencies between test cases
- **Fast execution** - Unit tests should run quickly

### Phase 3: Implementation & Quality Improvement

#### 🔧 **Fix Existing Test Issues**

- **Timing dependencies** → Add proper waits, async handling, or mocks
- **Environment dependencies** → Use test fixtures and isolation
- **Brittle selectors** → Use data attributes for UI testing
- **Over-mocking** → Test real behavior when possible
- **Under-specified assertions** → Be explicit about expectations
- **Flaky tests** → Identify and eliminate non-deterministic behavior

#### 🏗️ **Create Missing Tests**

- **Unit tests** - Test individual functions/methods in isolation
- **Integration tests** - Test component interactions
- **End-to-end tests** - Test complete user workflows
- **Error handling tests** - Test exception scenarios
- **Edge case tests** - Boundary conditions and unusual inputs

#### 📊 **Test Quality Enhancements**

- **Improve assertions** - More specific, meaningful checks
- **Add test documentation** - Explain complex test scenarios
- **Refactor test code** - Remove duplication, improve readability
- **Optimize test performance** - Faster setup, parallel execution
- **Update test tools** - Modern testing frameworks and utilities

### Phase 4: Verification & Maintenance

- **Run full test suite** - Ensure all tests pass consistently
- **Verify coverage targets** - Meet project coverage requirements
- **Test performance** - Ensure test suite runs efficiently
- **Update CI/CD** - Integrate new tests into automated pipelines
  - For recursionpharma repos: Verify tests pass in Codefresh after pushing
  - If CI fails, use the `inspect-codefresh-failure` skill to analyze build logs
- **Document test strategy** - Clear guidance for future testing

Test target (issue to fix, feature to test, or coverage to improve): $ARGUMENTS

