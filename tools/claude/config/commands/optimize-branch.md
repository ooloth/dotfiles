---
description: Optimize how a solution is implemented on the current branch before opening a PR.
---

## Your role

Protect users of this software by scrutinizing it closely before it ships. Focus on strategic insight, not just thorough auditing.

## Context

- Correctness matters - is anything broken or incomplete?
- Performance matters - is anything unnecessarily inefficient?
- Maintainability matters - could different shapes make intentions more obvious?

## Process

**Work through ALL phases below in order.** Catch fundamental issues early (Phases 0-1), collect evidence silently (Phases 2-4), then present a synthesized, prioritized picture (Phase 5).

---

### Phase 0: Problem Validation

Before diving into implementation details, understand the purpose:

1. What user/developer pain point does this change address?
2. Who experiences this problem?
3. What outcome are they trying to achieve?
4. Is this the simplest way to achieve that outcome?
5. Could we solve the underlying need differently?

**Present to user:**
- The problem you understand this to solve
- The outcome it's trying to achieve
- Any simpler alternatives you can see to achieving that outcome

**Ask for confirmation:** "Did I understand the problem and desired outcome correctly?"

Wait for confirmation before proceeding to Phase 1.

---

### Phase 1: Survey & Initial Hypothesis

**Evidence gathering:**

1. List all files changed on this branch (vs main/master)
2. Read each changed file to understand the implementation
3. Read similar/related unchanged files to understand existing codebase patterns:
   - How are similar problems solved elsewhere?
   - What patterns exist for error handling, testing, naming, architecture?
   - Are there utilities or abstractions already available?
4. Identify what was implemented and how
5. Categorize changes into themes (feature logic, tests, refactoring, etc.)
6. **Form initial hypothesis:** Are there fundamental design issues that would require major rework?

**Present to user:**
- What you believe the original requirements/goals were
- What was actually implemented
- How changes are grouped thematically
- What existing codebase patterns are relevant
- **Initial hypothesis:** Any fundamental design issues? (e.g., "This reimplements functionality that exists in X", "This could be 3 lines using existing utility Y", "This approach conflicts with pattern Z used elsewhere")

**Checkpoint:** "Is there a fundamental design issue we should address before diving into detailed review? Or should I proceed with deep analysis?"

If fundamental redesign needed, discuss approach. Otherwise, continue to Phases 2-4.

---

### Phases 2-4: Deep Review (Evidence Collection)

**IMPORTANT:** Do NOT present findings after each phase. Collect all evidence silently and look for patterns. You will synthesize and prioritize everything in Phase 5.

---

#### Phase 2: Correctness Review

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

**Developer Experience:**
- Will using this API/feature be intuitive or frustrating?
- Are error messages actionable?
- Is this "teachable" - can others learn good patterns from this code?

---

#### Phase 3: Performance Review

For each changed file, identify:

- Unnecessary inefficiencies (N+1 queries, missing memoization, etc.)
- Algorithmic improvements (O(n²) → O(n))
- Resource waste (unclosed connections, memory leaks)

**Only report actual problems**, not theoretical optimizations.

---

#### Phase 4: Maintainability Review

Check for:

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

**Future Lens:**
- How easy will this be to change when requirements evolve?
- What's the maintenance burden?
- What's the blast radius of future changes?

**Developer Experience:**
- Does this make the codebase better or worse as a place to work?
- Is this code a joy or a chore to maintain?

---

### Phase 5: Synthesis & Prioritization

Now connect the dots and present the complete picture:

**1. Root Cause Analysis**
Look across all findings:
- Are there patterns? (e.g., "All 5 bugs stem from not validating inputs")
- Is there a fundamental design issue causing multiple problems?
- Would a redesign eliminate many smaller issues?

**2. Top 3 Highest-Impact Improvements**
Identify the changes that would make the biggest difference:
- What would fix the most issues?
- What would prevent future problems?
- What would most improve maintainability?

**3. Group Remaining Findings by Theme**
Organize everything else (if worth mentioning):
- Group related issues together
- De-duplicate similar findings
- **Filter out noise** - don't report trivial issues if they distract from what matters

**4. Calibrate Confidence**
For each finding, indicate certainty:
- "This is definitely broken" vs "This might be an issue" vs "Consider this alternative"

**Present to user in this format:**

```
## Optimization Review

### Root Cause
[If applicable: What fundamental issue explains multiple findings?]
[If applicable: Would a different design approach eliminate many of these issues?]

### Top 3 Highest-Impact Improvements

1. **[Improvement name]**
   - Issue: [what's wrong]
   - Impact: [why this matters]
   - Suggested fix: [specific approach]
   - Confidence: [High/Medium/Low]
   - Affects: [which files/areas]

2. **[Improvement name]**
   - [same format]

3. **[Improvement name]**
   - [same format]

### Other Findings by Theme

#### [Theme name] (e.g., "Testing Gaps", "Security", "Code Quality")
- [Issue] in `file:line` - [Suggested fix] - [Why] - Confidence: [High/Medium/Low]
- [Issue] in `file:line` - [Suggested fix] - [Why] - Confidence: [High/Medium/Low]

#### [Theme name]
- [Issues...]

### What to Ignore
[Low-value findings that aren't worth addressing]
```

**Ask user:** "Which of these should we address? All Top 3? Some subset?"

Wait for approval before proceeding to implementation.

---

## Implementation Workflow

After user selects which improvements to make:

1. **Group by theme** - Organize approved fixes into logical batches
2. **Work incrementally** - Implement one theme at a time
3. **Pause for commits** - After each theme (behavior + tests + docs), stop and let me commit
4. **No over-engineering** - Only fix approved items, don't add "nice-to-haves" unless asked

---

## What NOT to do

- Don't add features beyond the branch scope
- Don't refactor code you're not changing
- Don't add docstrings/comments to untouched code
- Don't add error handling for impossible scenarios
- Don't create abstractions for one-time use
- Don't design for hypothetical future requirements
- Don't report minor issues if they distract from major ones

---

## Documentation Check

Before marking complete, verify:

- Do user-facing changes need README/docs updates?
- Are breaking changes documented with migration notes?
- Are new configuration options or environment variables documented?
- Are new dependencies documented (why needed, how to install)?
- Does changed behavior need updating in help text, comments, or guides?

If documentation updates are needed, implement them before completion.

---

## Completion

Only after completing all phases, implementing approved changes, and updating documentation, report: "Branch optimization complete. Ready to open PR."
