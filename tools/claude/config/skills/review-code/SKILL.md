---
name: review-code
description: Core code analysis engine shared by review-pr and review-branch. Reads changed files, loads conventions, and performs correctness/performance/maintainability review. Outputs neutral findings for the calling skill to format for its specific audience. Invoke directly for ad-hoc analysis when you want raw findings without branch or PR ceremony — specify which files to analyze as the argument.
argument-hint: '[file paths or description of what to analyze]'
effort: high
model: opus
---

## Your role

Perform deep, grounded code analysis. Read the actual code (not just diffs), understand existing codebase patterns, and surface real issues with concrete evidence. Output neutral findings that the calling skill formats for its specific audience (teammate in a PR, or yourself on a branch).

## Inputs from calling skill

Before invoking this skill, the calling skill (if applicable) should have established:

- The list of changed files (paths relative to repo root)
- How to read file contents (local paths for branch review; raw GitHub URLs or `gh` for PR review)
- Any context that should inform the review (e.g., author's stated intent, problem being solved)

---

## Phase A: Read Changed Files

**Skip non-reviewable files:**

- package-lock.json, \*.lock, yarn.lock, Gemfile.lock
- Generated code (_.generated._, \*\_pb2.py, etc.)
- Test snapshots (**snapshots**/\*)
- Vendored dependencies (vendor/, node_modules/ if committed)
- Binary files
- **Formatting-only changes** (detect hunks that are whitespace/style only)

For each reviewable file, read the **full file content**, not just the diff. The diff shows changes but not surrounding code.

**Show progress:**

```
Reading changed files:
✓ auth.py (1/5)
✓ api.py (2/5)
...
```

**Output:** "✓ Read [N] changed files ([M] skipped as non-reviewable)"

---

## Phase B: Read Existing Patterns

Read **2-3 similar/related unchanged files** to understand how this codebase solves similar problems:

- How does existing code handle authentication/caching/error handling/etc?
- What utilities exist? (Don't suggest reinventing the wheel)
- What conventions are used? (naming, architecture, testing patterns)

**Output what you found:**

```
✓ Reviewed existing patterns:
- Error handling: utils/errors.py uses custom exception classes with error codes
- Testing: All API functions have corresponding test_*.py with parametrized tests
- Authentication: auth/session.py uses JWT with Redis cache
```

**Output:** "✓ Analyzed existing patterns ([N] related files)"

---

## Phase C: Load Conventions

Based on changed file types, invoke relevant conventions skills **before reviewing**:

- Python files (.py) → invoke `conventions-for-python`
- Test files (test\__.py, _.test.ts, \*.spec.ts, etc.) → invoke `conventions-for-tests`
- Type definitions (\*.d.ts, Pydantic models, Zod schemas, TypeScript interfaces) → invoke `conventions-for-types`
- Multiple new files or new folder structure → invoke `conventions-for-architecture`

**Output:** "✓ Loaded conventions ([list loaded])"

---

## Phase D: Correctness Review

**Output:** "✓ Completed correctness review"

**Completeness:**

- Are the stated goals met? Is the feature complete?
- Are there obvious edge cases we should handle?

**Consistency:**

- Does this follow the same patterns as similar code (from Phase B)?
- Are existing utilities/abstractions used, or is this reinventing the wheel?
- Does error handling match the project's conventions?
- Do naming, structure, and style match surrounding code?

**Bugs & Error Handling:**

- Are there any logic errors or potential crashes?
- Are errors propagated consistently (same pattern throughout)?
- Do error messages provide helpful context for debugging?
- Do we fail fast where appropriate, or handle gracefully where needed?
- Could any runtime errors be shifted left to compile-time type checks?
- Could refactoring to different patterns make any error states impossible?
- Are all failure modes accounted for?

**Security:**

- Is user input validated at system boundaries (APIs, CLI args, file uploads, etc.)?
- Are there injection risks (SQL, command, XSS, path traversal)?
- Are credentials or secrets properly handled (not logged, not in version control)?
- Are file permissions and access controls appropriate?
- Are external dependencies from trusted sources?

**Only report actual security violations, not theoretical what-ifs.**

**Compatibility:**

- Will this change break existing behavior or workflows?
- Are there migration considerations for existing users?
- Are version/platform requirements reasonable and documented?
- Are new dependencies necessary and justified?

**Developer Experience:**

- Will using this API/feature be intuitive or frustrating?
- Are error messages actionable?
- Is this "teachable" — can others learn good patterns from this code?

**Testing:**

- Is all new behavior tested?
- Are there code paths with zero test coverage?
- Can test cases be consolidated (e.g., parametrized tests)?
- Are invariants checked in tests?
- Are error cases and edge cases tested?
- **Specify exact test cases needed:** not "add tests" but "add tests for: expired token, malformed token, missing token, token with wrong signature"

**Documentation:**

- Do user-facing changes need README/docs updates?
- Are breaking changes documented with migration notes?
- Are new configuration options or environment variables documented?
- Are new dependencies documented (why needed, how to install)?
- Does changed behavior need updating in help text, comments, or guides?

---

## Phase E: Performance Review

**Output:** "✓ Completed performance review"

For each changed file, identify:

- Unnecessary inefficiencies (N+1 queries, missing memoization, etc.)
- Algorithmic improvements (O(n²) → O(n))
- Resource waste (unclosed connections, memory leaks)

**Only report actual problems**, not theoretical optimizations.

---

## Phase F: Maintainability Review

**Output:** "✓ Completed maintainability review"

**Design Coherence:**

- Step back: Does the overall approach make sense, or is there a simpler mental model?
- If starting fresh with what we know now, would we design it differently?
- Are there signs of exploratory coding (multiple approaches to same problem, inconsistent patterns)?
- Is the solution internally consistent, or does it solve similar problems in different ways?
- Does the implementation match the problem's inherent complexity, or is it over/under-engineered?

**If you see a significantly simpler design:**

- Describe the alternative approach with concrete examples
- Explain why it's simpler (fewer concepts, less indirection, clearer intent)
- Show what changes would be needed
- **Don't let current implementation size prevent proposing a better approach** — the biggest wins are often catching overcomplicated solutions before they ship
- **Redesign scope boundary:** If it would touch >100 lines or >5 files, note as design debt but don't block the current work

**Simplicity:**

- Could this be expressed more directly?
- Is there unnecessary complexity, abstraction, or indirection?
- Is the solution as declarative as possible?

**Clarity:**

- Would a new maintainer struggle to understand intent?
- Are domain types used instead of primitives?
- Is logic overly repetitive or verbose?
- Would well-named helper functions and better types help clarify what the code is aiming to do?

**Noise:**

- Is there any dead code, commented code, or unused imports?
- Are there unnecessary comments explaining obvious code?
- Any unnecessary backwards compatibility support that can be removed?
- Any remnants from exploration (partial refactors, abandoned approaches)?
- Any duplicate or near-duplicate code when existing code could have been reused?

**Future Lens:**

- How easy will this be to change when requirements evolve?
- What's the maintenance burden?
- What's the blast radius of future changes?

**Developer Experience:**

- Does this make the codebase better or worse as a place to work?
- Is this code a joy or a chore to maintain?

---

## Phase G: What's Good

Note positive findings **throughout** Phases D-F as you encounter them — don't batch at the end:

- Clever solutions
- Good abstractions
- Thorough testing
- Clear naming
- Thoughtful error handling
- Consistent use of existing patterns

Aim for **at least 1:1 positive to negative ratio.**

---

## Output

Present findings in a neutral structured list. The calling skill maps these to its audience:

- **review-pr** maps Critical→🚫, Important→💡, Minor→✨, Questions→🤔, Praise→👍 and formats findings as comment candidates for a teammate
- **review-branch** maps to Top Improvements + Other Findings by Theme with root cause analysis for self-directed implementation

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

**Volume:** Focus on 3-5 most impactful issues. If there are 10+, group related ones or note "broader refactor needed" rather than listing every instance.
