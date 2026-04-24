---
name: review-code-parallel
description: Run a comprehensive code review using parallel agents, then synthesize findings. TRIGGER when the user asks you to review a particular part of the codebase.
allowed-tools: Bash Read Grep Glob
effort: high
model: opus
---

# Code Review

Run a comprehensive code review using parallel agents, then synthesize findings.

## Scope

Determine what code to review using this priority:

1. **User specifies scope** - If the user provides a branch name, commit SHA, PR number/URL, or file paths, review that
2. **On a feature branch** - Review all changes on current branch vs main/master/trunk (`git diff main...HEAD`)
3. **On main/master/trunk with staged changes** - Review staged files (`git diff --staged`)
4. **On main/master/trunk, nothing staged** - Review the latest commit (`git show HEAD`)

Examples:

- "review my branch" → branch diff
- "review pr 123" or "review https://github.com/org/repo/pull/123" → fetch PR via `gh`
- "review commit abc123" → that specific commit
- "review src/auth.ts" → just that file's recent changes
- (no scope given, on feature branch) → automatic branch diff
- (no scope given, on main/master/trunk branch) → ask user what to review

## Instructions

Launch all 9 agents in parallel using a single message with multiple Agent tool calls:

### Agent 1: Test Runner

```
Run relevant tests for the changed files. Report:
- Which tests were run
- Pass/fail status
- Any test failures with details
```

### Agent 2: Linter & Static Analysis

```
Run linters AND collect IDE diagnostics (using getDiagnostics) for the changed files.

Report:
- Linting tool(s) used
- Any warnings or errors found
- Auto-fixable vs manual fixes needed
- Type errors or unresolved references from IDE diagnostics
```

### Agent 3: Code Reviewer

```
First, check if CLAUDE.md or a similar project style guide exists. If so, read it to understand project conventions.

Review the code changes and provide up to 5 concrete improvements, ranked by:
- Impact (how much this improves the code)
- Effort (how hard it is to implement)

Only include genuinely important issues. If the code is clean, report fewer items or none.

Format each suggestion as:
1. [HIGH/MED/LOW Impact, HIGH/MED/LOW Effort] Title
   - What: Description of the issue
   - Why: Why this matters
   - How: Concrete suggestion to fix

Focus on non-obvious improvements - skip formatting, naming nitpicks, and things linters catch.
```

### Agent 4: Security Reviewer

```
Review the code changes for security concerns:
- Input validation and sanitization
- Injection risks (SQL, command, XSS)
- Authentication/authorization issues
- Secrets or credentials in code
- Error handling that leaks sensitive info

Also check error handling:
- Missing try/catch where needed
- Swallowed errors hiding problems
- Unhelpful error messages

Report issues with severity (Critical/High/Medium/Low) and specific file:line references.
If no issues found, report "No security concerns identified."
```

### Agent 5: Quality & Style Reviewer

```
First, check if CLAUDE.md or a similar project style guide exists. If so, read it to understand project conventions.

Review the code changes for quality and style issues:

Quality:
1. Complexity - functions too long, deeply nested, high cyclomatic complexity
2. Dead code - unused imports, unreachable code, unused variables
3. Duplication - copy-pasted logic that should be abstracted

Style Guidelines:
4. Naming conventions - does naming match project patterns and style guide?
5. File/folder organization - are files in the right place?
6. Architectural patterns - does code follow established patterns in the codebase?
7. Consistency - does new code match the style of surrounding code?
8. Project conventions - does code follow rules in the project style guide (if present)?

For each issue found, provide:
- File and location
- What the issue is
- Suggested fix

If code is clean, report "No quality or style issues identified."
```

### Agent 6: Test Quality Reviewer

```
Review test coverage and quality for the changed code:

Coverage (with ROI lens):
- Are critical paths tested? (auth, payments, data integrity)
- Are edge cases that matter tested?
- Is the coverage proportionate to the risk? (not all code needs equal coverage)
- Would adding more tests here provide diminishing returns?

Quality:
- Do tests verify behavior, not implementation details?
- Will these tests break for the wrong reasons? (testing internals, brittle selectors)
- Are assertions focused on outcomes users care about?
- Would these tests catch real bugs without false positives?

Test Code Quality:
- Are there many similar tests that could be parameterized/data-driven?
- Is there copy-pasted setup that should be extracted to helpers/fixtures?
- Could table-driven tests reduce boilerplate while improving clarity?
- Is test code held to the same quality standards as production code?

Flakiness Risk:
- Are there timing dependencies, race conditions, or order-sensitive assertions?
- Do tests rely on external state that could change?
- Are async operations properly awaited/mocked?

Anti-patterns:
- Testing implementation details (private methods, internal state)
- Mocking so heavily that tests don't verify real behavior
- Tests that pass but don't actually assert meaningful outcomes
- Coverage for coverage's sake on low-risk code

Report issues with specific suggestions. If tests are well-balanced, report "Test coverage is appropriate and behavior-focused."
```

### Agent 7: Performance Reviewer

```
Review the code changes for performance concerns:
- N+1 queries or inefficient data fetching
- Blocking operations in async contexts
- Unnecessary re-renders (React) or recomputations
- Memory leaks (unclosed resources, growing collections)
- Missing pagination for large datasets
- Expensive operations in hot paths

For each concern, explain the impact and suggest a fix.
If no concerns, report "No performance concerns identified."
```

### Agent 8: Dependency, Breaking Changes & Deployment Safety Reviewer

```
Review changes for dependency, compatibility, and deployment concerns:

Dependencies (if package files changed):
- Are new dependencies justified? Check if functionality could use existing deps
- Are dependencies well-maintained? (check for recent commits, known vulnerabilities)
- Impact on bundle size for frontend dependencies

Breaking Changes (if public APIs or exports changed):
- Are any public interfaces, types, or exports modified?
- Would existing consumers of this code break?
- Is a version bump needed? (major for breaking, minor for features, patch for fixes)

Deployment Safety:
- Are there database migrations that could fail or lock tables?
- Is there backwards compatibility with existing data/state in production?
- Are there deployment ordering issues? (config changes, service dependencies)
- Would a feature flag help with safe rollout?
- Could this be rolled back safely if issues arise?

Observability:
- If this fails in production, how would we know?
- Are there logs, metrics, or alerts that would surface issues?
- Are error cases observable, not silent?
- Do critical paths have monitoring coverage?

Report issues with specific file references.
If no concerns, report "No dependency, compatibility, or deployment concerns."
```

### Agent 9: Simplification & Maintainability Reviewer

```
Review the code changes with fresh eyes, asking "could this be simpler?"

Simplification:
- Are there abstractions that don't pull their weight?
- Could we achieve the same result with less code?
- Are we solving problems we don't actually have?
- Is there a more straightforward approach using existing patterns/libraries?

Maintainability ROI:
- Will future developers understand this easily?
- Does the complexity match the problem complexity?
- Are we adding cognitive load for marginal benefit?
- Would a "dumber" solution be easier to maintain long-term?

Look for:
- Premature abstractions (helpers used once, unnecessary indirection)
- Over-configured solutions when simple would suffice
- Framework-level solutions for one-off problems
- Clever code that sacrifices clarity

Change Atomicity & Reviewability:
- Does this change represent one logical unit of work? (atomic commit)
- Are there unrelated changes mixed in that should be separate commits?
- Could any cleanup/refactoring be split out as a preceding commit?
- Is there feature work bundled with unrelated fixes?
- Is this sized appropriately for PR review? (not so large it's overwhelming)
- Does it include enough context to review without jumping everywhere?
- Would splitting this up lose important context a reviewer needs?

For each finding, explain:
- What could be simplified
- The simpler alternative
- Maintenance cost saved

If the code is appropriately simple and atomic, report "Code complexity is proportionate to the problem and changes are well-scoped."
```

## After Agents Complete: Synthesize Results

Collect all agent results and produce a prioritized summary:

1. **Categorize findings** - separate issues (should fix) from suggestions (nice to have)
2. **Rank by severity** - Critical > High > Medium > Low across all agents
3. **Collapse clean results** - agents with no findings get one-line summary
4. **Give verdict** - Ready to merge / Needs attention / Needs work

### Output Format

```
## Code Review Summary

### Needs Attention (X issues)

A1. [Security] TL;DR (HIGH impact, LOW effort)
   • Problem summary
   • Fix summary

A2. [Tests] TL;DR (HIGH impact, MED effort)
   • Problem summary
   • Fix summary

### Suggestions (X items)

B1. [Quality] TL;DR (HIGH impact, LOW effort)
   • Problem summary
   • Fix summary

B2. [Perf] TL;DR (MED impact, MED effort)
   • Problem summary
   • Fix summary

B3. [Deps] TL;DR (MED impact, LOW effort)
   • Problem summary
   • Fix summary

### All Clear

- Tests (N passed)
- Linter (no issues)
- [other clean agents...]

### Verdict: [Ready to Merge | Needs Attention | Needs Work]

[One sentence summary of what to do next]
```

### Verdict Guidelines

- **Ready to Merge** - All tests pass, no critical/high issues, suggestions are optional
- **Needs Attention** - Has medium issues or important suggestions worth addressing
- **Needs Work** - Has critical/high issues or failing tests that must be fixed
