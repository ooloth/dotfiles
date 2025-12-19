---
description: Optimize how a solution is implemented on the current branch before opening a PR.
---

## Your role

Protect users of this software by scrutinizing it closely before it ships.

## Context

- Correctness matters - is anything broken or incomplete?
- Performance matters - is anything unnecessarily inefficient?
- Maintainability matters - could different shapes make intentions more obvious?

## Process

**Work through ALL phases below in order.** After each phase, present findings and wait for approval before making changes. Once changes from a phase are implemented (or skipped), automatically continue to the next phase until all phases are complete.

### Phase 1: Survey

1. List all files changed on this branch (vs main/master)
2. Read each changed file to understand the implementation
3. Read similar/related unchanged files to understand existing codebase patterns:
   - How are similar problems solved elsewhere?
   - What patterns exist for error handling, testing, naming, architecture?
   - Are there utilities or abstractions already available?
4. Identify the primary feature/fix this branch delivers
5. Categorize changes into themes (feature logic, tests, refactoring, etc.)

Present a summary including:
- What you believe the original requirements/goals were
- What was actually implemented
- How changes are grouped thematically
- What existing codebase patterns are relevant

**Ask for confirmation:** "Did I understand the requirements correctly? Anything I'm missing about the goals?"

Wait for confirmation before proceeding to Phase 2.

### Phase 2: Correctness Review

Check each theme for:

**Completeness:**

- Are the stated goals met? Is the feature complete?
- Are there obvious edge cases we should handle?

**Consistency:**

- Does this follow the same patterns as similar code in the codebase?
- Are existing utilities/abstractions used, or is this reinventing the wheel?
- Does error handling match the project's conventions?
- Do naming, structure, and style match surrounding code?

**Bugs & Error Handling:**

- Are there any logic errors or potential crashes?
- Are errors propagated consistently (same pattern throughout)?
- Do error messages provide helpful context for debugging?
- Do we fail fast where appropriate, or handle gracefully where needed?
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

**Testing:**

- Is all new behavior tested?
- Are there code paths with zero test coverage?
- Can test cases be consolidated (e.g., parametrized tests)?
- Are invariants checked in tests?
- Are error cases and edge cases tested?

**Priority criteria:**
- **High**: Bugs, security issues, breaking changes, missing core functionality
- **Medium**: Quality issues, missing tests, inconsistencies, compatibility concerns
- **Suggestions**: Nice-to-haves, simplifications, code quality improvements

**Report format:**

```
## Correctness Issues

### High Priority
- [Issue description] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning]

### Medium Priority
- [Issue description] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning]

### Suggestions
- [Nice-to-have improvement] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning]
```

### Phase 3: Performance Review

For each changed file, identify:

- Unnecessary inefficiencies (N+1 queries, missing memoization, etc.)
- Algorithmic improvements (O(n²) → O(n))
- Resource waste (unclosed connections, memory leaks)

**Only report actual problems**, not theoretical optimizations.

**Report format:**

```
## Performance Issues

### High Priority
- [Issue description] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning and impact]

### Medium Priority
- [Issue description] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning and impact]
```

### Phase 4: Maintainability Review

Check for:

**Design Coherence:**

- Step back: Does the overall approach make sense, or is there a simpler mental model?
- If starting fresh with what we know now, would we design it differently?
- Are there signs of exploratory coding (multiple approaches to same problem, inconsistent patterns)?
- Is the solution internally consistent, or does it solve similar problems in different ways?
- Does the implementation match the problem's inherent complexity, or is it over/under-engineered?

**Redesign threshold:** If you can see a significantly simpler design that better fits the problem:
- Describe the alternative approach with concrete examples
- Explain why it's simpler (fewer concepts, less indirection, clearer intent)
- Show what changes would be needed
- **Don't let current implementation size prevent proposing a better approach** - the biggest wins are often catching overcomplicated solutions before they ship

**Simplicity:**

- Could this be expressed more directly?
- Is there unnecessary complexity, abstraction, or indirection?
- Is the solution as declarative as possible?

**Clarity:**

- Would a new maintainer struggle to understand intent?
- Are domain types used instead of primitives?
- Is logic overly repetitive or verbose?

**Noise:**

- Is there any dead code, commented code, or unused imports?
- Are there unnecessary comments explaining obvious code?
- Any backwards-compatibility hacks that can be removed?
- Any remnants from exploration (partial refactors, abandoned approaches)?

**Report format:**

```
## Maintainability Issues

### Alternative Design (if applicable)
Current approach: [brief description]
Simpler approach: [concrete alternative with examples]
Why simpler: [fewer concepts, less indirection, clearer intent]
Changes needed: [what would need to change]

### High Priority
- [Issue description] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning]

### Medium Priority
- [Issue description] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning]

### Suggestions
- [Nice-to-have improvement] in `file:line`
  Suggested fix: [specific improvement]
  Why: [reasoning]
```

## Implementation Workflow

After reviews, for each issue to fix:

1. **Group by theme** - Organize fixes into logical batches
2. **Work incrementally** - Implement one theme at a time
3. **Pause for commits** - After each theme (behavior + tests + docs), stop and let me commit
4. **No over-engineering** - Only fix actual problems, don't add "nice-to-haves" unless asked

## What NOT to do

- Don't add features beyond the branch scope
- Don't refactor code you're not changing
- Don't add docstrings/comments to untouched code
- Don't add error handling for impossible scenarios
- Don't create abstractions for one-time use
- Don't design for hypothetical future requirements

## Documentation Check

Before marking complete, verify:

- Do user-facing changes need README/docs updates?
- Are breaking changes documented with migration notes?
- Are new configuration options or environment variables documented?
- Are new dependencies documented (why needed, how to install)?
- Does changed behavior need updating in help text, comments, or guides?

If documentation updates are needed, implement them before completion.

## Completion

Only after completing all 4 phases (Survey, Correctness, Performance, Maintainability), implementing approved changes, and updating documentation, report: "Branch optimization complete. Ready to open PR."
