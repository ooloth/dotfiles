---
description: Review a pull request with structured feedback
---

## Structured PR Review Process

### Phase 0: PR Identification

**Determine which PR to review:**

- **If PR number provided**: Use `gh pr view <number>` to fetch details
- **If no argument given**: Check current branch for associated PR using `gh pr view`
- **If ambiguous**: Ask user to clarify which PR to review
- **If no PR found**: Inform user and ask for PR number or URL

### Phase 1: Context Research

1. **Fetch PR details** using GitHub CLI (`gh pr view <number> --json body,commits,files`)
2. **CHECK CI STATUS** using `gh pr checks <number>` - ALL checks MUST pass before merge
3. **Fetch any GitHub issues mentioned in PR description** for requirements and context
4. **Check epic/project context** if part of larger initiative
5. **Understand the "why"** behind the changes - ask questions as needed

### Phase 2: CI Status Analysis (MANDATORY)

1. **Check all CI workflows** - Use `gh pr checks <number>` to verify status
2. **If CI is failing**:
   - Fetch detailed logs with `gh run view <run-id> --log-failed`
   - Identify root cause of failures
   - Assume ALL failures are caused by changes in the current branch
   - Provide specific fixes for each failure
3. **Common CI issues to check**:
   - Test failures (unit tests, integration tests, BATS tests)
   - Linting errors (shellcheck, eslint, etc.)
   - Build failures
   - Missing dependencies or configuration
4. **CRITICAL**: PR cannot be merged until ALL CI checks pass

### Phase 3: Code Analysis

1. **Diff review** - Understand all changes made (`gh pr diff <number>`)
2. **Bug detection** - Logic errors, edge cases
3. **Test coverage** - New tests for new functionality
4. **Quality assessment** - Style, clarity, maintainability
5. **Documentation** - Updated docs for changed behavior
6. **Security implications** - New vulnerabilities
7. **Performance impact** - Bottlenecks, missed opportunities
8. **Architectural changes** - Structural issues and inconsistencies
9. **Best practices** - Modern framework and language usage

### Phase 4: Actionable Feedback

- **CI FAILURES (BLOCKER)**: Any failing CI checks must be fixed before merge
- **Must fix**: Bugs, security issues, broken tests, CI failures
- **Should fix**: Performance issues, poor patterns
- **Consider**: Style improvements, refactoring opportunities
- **Praise**: Good patterns, clever solutions, thorough testing

**REMINDER**: Always start by checking CI status. A PR with failing CI cannot be merged regardless of code quality.

PR number or URL (optional - will check current branch if not provided): $ARGUMENTS
