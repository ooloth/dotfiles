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

Work through these phases in order. After each phase, present findings and wait for approval before making changes.

### Phase 1: Survey

1. List all files changed on this branch (vs main/master)
2. Read each changed file to understand the implementation
3. Identify the primary feature/fix this branch delivers
4. Categorize changes into themes (feature logic, tests, refactoring, etc.)

Present a summary of what was implemented and the themes you identified.

### Phase 2: Correctness Review

Check each theme for:

**Completeness:**

- Are the stated goals met? Is the feature complete?
- Are there obvious edge cases we should handle?

**Bugs:**

- Are there any logic errors or potential crashes?
- Will error cases be handled gracefully?

**Testing:**

- Is all new behavior tested?
- Are there code paths with zero test coverage?
- Can test cases be consolidated (e.g., parametrized tests)?
- Are invariants checked in tests?

**Report format:**

```
## Correctness Issues

### High Priority
- [Issue description] in `file:line`

### Medium Priority
- [Issue description] in `file:line`

### Suggestions
- [Nice-to-have improvement] in `file:line`
```

### Phase 3: Performance Review

For each changed file, identify:

- Unnecessary inefficiencies (N+1 queries, missing memoization, etc.)
- Algorithmic improvements (O(n²) → O(n))
- Resource waste (unclosed connections, memory leaks)

**Only report actual problems**, not theoretical optimizations.

### Phase 4: Maintainability Review

Check for:

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
