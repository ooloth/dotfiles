---
name: review-code
description: Core code analysis engine shared by review-pr and review-branch. Determines scope, launches 10 parallel specialized agents, and merges findings into a neutral output for the calling skill to format. Invoke directly for ad-hoc analysis when you want raw findings without branch or PR ceremony — specify which files to analyze as the argument.
argument-hint: '[file paths or description of what to analyze]'
allowed-tools: Bash Read Grep Glob
effort: high
model: opus
---

## Your role

Orchestrate a parallel code review. Determine scope, launch all 10 agents simultaneously, then merge their findings into neutral structured output for the calling skill to format.

## Step 1: Determine scope

Identify changed files using this priority:

1. **Argument provided** — use the specified file paths or description
2. **On a feature branch** — `git diff main...HEAD --name-only` (or master/trunk)
3. **On main with staged changes** — `git diff --staged --name-only`
4. **On main, nothing staged** — `git diff HEAD~1 --name-only`

**Skip non-reviewable files:**

- package-lock.json, \*.lock, yarn.lock, Gemfile.lock
- Generated code (_.generated._, \*\_pb2.py, etc.)
- Test snapshots (**snapshots**/\*)
- Vendored dependencies (vendor/, node_modules/ if committed)
- Binary files
- Formatting-only changes (whitespace/style only)

Output the reviewable file list before launching agents.

## Step 2: Launch all 10 agents in parallel

Send a single message containing all 10 Agent tool calls simultaneously. Pass each agent:

- The list of changed/reviewable files
- Its specific instructions below

---

### Agent 1: Test Runner

```
Run the test suite for the changed files listed below and report results.

Changed files:
[insert file list]

Instructions:
1. Identify the test framework and how to run tests (check package.json, Makefile, pyproject.toml, etc.)
2. Run the tests most relevant to the changed files
3. Report:
   - Which test command was run
   - Pass/fail counts
   - Any failures with error messages and stack traces
   - Whether all tests passed or attention is needed
```

---

### Agent 2: Correctness

```
Review the changed files for correctness issues.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed. For files under 500 lines, read the full file. For larger files, read each changed section plus ~30 lines of context.
2. Read 2-3 similar unchanged files to understand existing patterns for error handling, validation, etc.

Review for:
- Logic errors, off-by-one errors, incorrect conditionals
- Missing edge cases (empty input, null/None, zero, max values)
- Incomplete feature implementation (stated goals not fully met)
- Error propagation: are errors handled consistently with surrounding code?
- Backward compatibility: does this break existing callers or data?
- Are existing utilities/patterns reused, or is this reinventing the wheel?

For each issue: file:line | what's wrong | concrete impact | specific fix
Skip theoretical what-ifs — report actual problems in the code.
```

---

### Agent 3: Security

```
Review the changed files for security issues.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed, then read surrounding context.

Review for:
- Input validation at system boundaries (APIs, CLI args, file uploads, env vars)
- Injection risks: SQL, command injection, XSS, path traversal
- Authentication and authorization gaps
- Secrets or credentials hardcoded or logged
- Error messages that leak sensitive information (stack traces, internal paths, user data)
- File permissions and access controls
- External dependencies from untrusted sources

For each issue: file:line | what's wrong | severity (Critical/High/Medium/Low) | specific fix
Only report actual security violations, not theoretical what-ifs.
If no issues found, report "No security concerns identified."
```

---

### Agent 4: Performance

```
Review the changed files for performance issues.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed, then read surrounding context.
2. Check how similar operations are handled in unchanged files.

Review for:
- N+1 queries or repeated fetches inside loops
- Blocking operations in async contexts
- Missing memoization or caching where appropriate
- Memory leaks: unclosed connections, resources, growing collections
- Missing pagination for potentially large datasets
- Expensive operations in hot paths (per-request, per-item, per-frame)
- Algorithmic inefficiency (O(n²) where O(n) is straightforward)

For each issue: file:line | what's wrong | concrete impact | specific fix
Only report actual problems. Do not report theoretical micro-optimizations.
If no issues found, report "No performance concerns identified."
```

---

### Agent 5: Test Quality

```
Review the test coverage and quality for the changed files.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed.
2. Find and read the corresponding test files.
3. Read 2-3 existing test files to understand the project's test style.

Review for:
Coverage (with ROI lens):
- Are critical paths tested? (auth, payments, data integrity, error paths)
- Are edge cases that matter covered?
- Are there code paths with zero test coverage?
- Specify exact missing test cases: not "add tests" but "add tests for: expired token, missing token, token with wrong signature"

Test design:
- Do tests verify behavior, not implementation details?
- Will these tests break for the wrong reasons? (brittle selectors, testing internals)
- Are assertions focused on outcomes users care about?

Test code quality:
- Many similar tests that could be parameterized/data-driven?
- Copy-pasted setup that should be extracted to helpers/fixtures?
- Tests that pass but don't meaningfully assert anything?

Flakiness risk:
- Timing dependencies, race conditions, order-sensitive assertions?
- Reliance on external state that could change?
- Async operations not properly awaited/mocked?

For each issue: file:line | what's wrong | specific fix
If coverage is appropriate, report "Test coverage is appropriate and behavior-focused."
```

---

### Agent 6: Observability & Documentation

```
Review the changed files for observability and documentation gaps.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed.
2. Check existing logging, metrics, and analytics patterns in related files.
3. Check README, docs, help text, and changelogs for areas that need updating.

Observability:
- Does new user-facing behavior have corresponding logging, metrics, or analytics?
- Are new error paths surfaced (logged, tracked) or silently swallowed?
- Were existing logging/tracing calls changed or removed — is that intentional?
- If this fails in production, how would we know? Is it diagnosable?

Documentation:
- Do user-facing changes need README or docs updates?
- Are breaking changes documented with migration notes?
- Are new config options or environment variables documented?
- Are new dependencies documented (why needed, how to install)?
- Does changed behavior need updating in help text or guides?

For each issue: file:line | what's wrong | specific fix
If no gaps found, report "No observability or documentation gaps identified."
```

---

### Agent 7: Dependencies & Deployment

```
Review the changed files for dependency and deployment concerns.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed.
2. If package files changed, read them in full.

Dependencies (if package files changed):
- Are new dependencies justified? Could existing deps cover this?
- Are dependencies well-maintained? (check for recent activity, known issues)
- Frontend deps: impact on bundle size?

Breaking changes (if public APIs or exports changed):
- Are any public interfaces, types, or exports modified?
- Would existing consumers break?
- Is a version bump needed? (major for breaking, minor for features, patch for fixes)

Deployment safety:
- Database migrations that could fail or lock tables?
- Backward compatibility with existing data/state in production?
- Deployment ordering issues? (config changes, service dependencies)
- Would a feature flag help with safe rollout?
- Could this be rolled back safely if issues arise?

For each issue: file:line | what's wrong | specific recommendation
If no concerns found, report "No dependency or deployment concerns identified."
```

---

### Agent 8: Design & Expressiveness

```
Review the changed files for design quality and expressiveness.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed.
2. Read related unchanged files to understand existing design patterns and conventions.
3. Read ~/.claude/conventions/types.md if it exists.

Design coherence:
- Does the overall approach make sense, or is there a simpler mental model?
- Are there signs of exploratory coding (multiple approaches, inconsistent patterns)?
- Is the solution internally consistent, or similar problems solved differently?
- Does implementation match the problem's inherent complexity (not over/under-engineered)?

Expressiveness:
- Are domain-specific types used instead of primitives? (str, int, bool where a named type would express intent)
- Do types enforce invariants and make invalid states unrepresentable?
- Are function signatures expressive of the domain they model?
- Are there overly broad types (Any, untyped dicts) that provide no safety or documentation value?
- Missing type annotations where they'd add clarity?

Abstraction ROI:
- Do abstractions pull their weight? (used more than once, clearer than inline)
- Is there unnecessary indirection or wrapping?
- Are there helpers that exist for a single call site?

If you see a significantly simpler design, describe the alternative with concrete examples.
Note as design debt (don't block current work) if it would touch >100 lines or >5 files.

For each issue: file:line | what's wrong | specific alternative
```

---

### Agent 9: Readability & Simplicity

```
Review the changed files for readability and simplicity.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed, then read surrounding context.

Readability:
- Would a new maintainer struggle to understand intent?
- Is logic overly clever or indirect when a dumber approach would be clearer?
- Are there long functions or deeply nested blocks that should be extracted?
- Is there unnecessary verbosity — could the same intent be expressed in fewer lines?

Simplicity:
- Are we solving problems we don't actually have?
- Is there premature generality (configurable where hardcoded would suffice)?
- Framework-level solutions for one-off problems?
- Is the complexity proportionate to the problem?

Code noise:
- Dead code, commented-out code, unused imports or variables?
- Unnecessary backwards-compatibility shims?
- Remnants from exploration (partial refactors, abandoned approaches)?
- Duplicate or near-duplicate code when existing code could have been reused?

Change atomicity:
- Does this represent one logical unit of work?
- Are unrelated changes mixed in that should be separate commits?
- Would splitting out cleanup/refactoring as a preceding commit help reviewability?

For each issue: file:line | what's wrong | simpler alternative
If the code is appropriately simple, report "Code complexity is proportionate to the problem."
```

---

### Agent 10: Style & Consistency

```
Review the changed files for style and consistency.

Changed files:
[insert file list]

Instructions:
1. Run `git diff` to read what changed.
2. Read ~/.claude/conventions/ files relevant to the changed file types:
   - Python files (.py) → python.md
   - Test files → tests.md
   - Type definitions → types.md
   - Multiple new files or new folder structure → architecture.md
3. Read 2-3 similar unchanged files to understand the project's naming and style conventions.

Review for:
- Naming: do identifiers match the project's conventions and surrounding code?
- File and folder organization: are files in the right place?
- Architectural patterns: does new code follow established patterns in the codebase?
- Consistency: does new code match the style of surrounding code?
- Project conventions: does code follow rules in any project style guide (CLAUDE.md, etc.)?

For each issue: file:line | what's wrong | what convention is being violated | suggested fix
If style is consistent, report "No style or consistency issues identified."
```

---

## Step 3: Merge findings

Collect all agent results. Map each finding to the neutral output schema:

- **Critical** — correctness bugs, security vulnerabilities, failing tests, broken behavior
- **Important** — performance problems, test gaps on critical paths, significant design issues, deployment risks
- **Minor** — style, readability, small simplifications, documentation gaps
- **Questions** — genuine design uncertainties worth discussing
- **Praise** — good patterns, clever solutions, thorough tests, clear naming

Focus on 3-5 most impactful issues per severity level.

```
## Code Analysis Findings

### Praise
- [file:line] [what's good and why, grounded in actual code]

### Issues

#### Critical
- [file:line] | [what's wrong] | Impact: [concrete impact with example] | Fix: [specific approach with code] | Test cases: [exact scenarios] | Confidence: High

#### Important
- [file:line] | [what's wrong] | Impact: [concrete impact] | Fix: [specific approach] | Confidence: High/Medium

#### Minor
- [file:line] | [what's wrong] | Fix: [specific approach] | Confidence: Medium/Low

### Questions
- [file:line] | [genuine uncertainty or alternative worth discussing]

### Patterns Observed
- [pattern that should inform how fixes and suggestions are expressed]
```

The calling skill (`review-pr` or `review-branch`) formats these findings for its specific audience. When invoked directly, present findings as-is.
