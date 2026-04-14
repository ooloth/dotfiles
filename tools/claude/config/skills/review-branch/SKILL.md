---
name: review-branch
description: Look for opportunities to optimize the approach and/or implementation of the solution to a problem you see on the current branch (relative to its base branch). Use when the user asks you to assess, analyze, improve, optimize, review or validate the current branch or its changes.
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

**For bug fixes or small changes (<5 files, <100 lines), this can be brief.**

**Present to user:**

- The problem you understand this to solve
- The outcome it's trying to achieve
- Any simpler alternatives you can see to achieving that outcome

**Ask for confirmation:** "Did I understand the problem and desired outcome correctly?"

Wait for user response before proceeding to Phase 1.

---

### Phase 1: Survey & Initial Hypothesis

**Evidence gathering:**

1. List all files changed on this branch (vs main/master)
2. **For large branches (>20 files):** Focus on highest-impact files, don't try to review everything
3. Read each changed file to understand the implementation
4. Read **2-3 similar/related unchanged files** to understand existing codebase patterns:
   - How are similar problems solved elsewhere?
   - What patterns exist for error handling, testing, naming, architecture?
   - Are there utilities or abstractions already available?
5. Identify what was implemented and how
6. Categorize changes into themes (feature logic, tests, refactoring, etc.)
7. **Form initial hypothesis:** Are there fundamental design issues that would require major rework?

**Present to user:**

- What you believe the original requirements/goals were
- What was actually implemented
- How changes are grouped thematically
- What existing codebase patterns are relevant (from the 2-3 similar files you read)
- **Initial hypothesis:** Any fundamental design issues? (e.g., "This reimplements functionality that exists in X", "This could be 3 lines using existing utility Y", "This approach conflicts with pattern Z used elsewhere")

**Redesign scope boundary:** If a redesign would require touching >100 lines or >5 files, note it as design debt but don't block this PR. Focus on incremental improvements.

**Checkpoint:** "Is there a fundamental design issue we should address before diving into detailed review? Or should I proceed with deep analysis?"

Wait for user response. If fundamental redesign needed, discuss approach. Otherwise, continue to Phases 2-4.

---

### Phases 2-4: Deep Review

**Invoke the `review-code` skill**, passing:

- **Files:** the changed files list from Phase 1
- **How to read them:** local file paths (files are on disk)
- **Context:** the problem statement and desired outcome from Phase 0; the change themes and initial hypothesis from Phase 1

review-code performs a full read of all changed files and 2-3 related unchanged files, loads relevant conventions, and runs correctness, performance, and maintainability analysis — noting positive findings throughout.

**Output:** neutral findings structured as Praise, Issues (Critical/Important/Minor), Questions, and Patterns Observed. Phase 5 maps these to the branch review format.

---

### Phase 5: Synthesis & Prioritization

Map review-code's neutral findings to the branch review format and connect the dots:

**1. Root Cause Analysis**
Look across all findings - **only if there IS a pattern:**

- Are multiple issues caused by the same fundamental problem?
- Would fixing one thing eliminate many smaller issues?
- Is there a design issue that explains several bugs?

**2. Top Improvements**
Identify the **3-5 highest-impact** changes:

- What would fix the most issues?
- What would prevent future problems?
- What would most improve maintainability?

**3. Group Remaining Findings by Theme**
Organize everything else (if worth mentioning):

- Group related issues together
- De-duplicate similar findings
- **Filter out noise** - don't report trivial issues if they distract from what matters
- **Hard cap:** Report max 15 findings total outside top improvements

**4. Calibrate Confidence**
For each finding, indicate certainty:

- "This is definitely broken" vs "This might be an issue" vs "Consider this alternative"

**5. Escape Hatch**
If you genuinely find zero significant issues, say so: "No significant issues found. Code looks good to ship."

**Present to user in this format:**

```
## Optimization Review

### TLDR
Found [X] issues: [Y] critical, [Z] quality improvements
Recommend addressing: [A], [B], [C]

### Root Cause (only if applicable)
[What fundamental issue explains multiple findings, if any]
[Would a different design approach eliminate many of these issues?]

### Top Improvements (3-5 highest impact)

1. **[Improvement name]**
   - Issue: [what's wrong]
   - Impact: [why this matters]
   - Suggested fix: [specific approach]
   - Confidence: High/Medium/Low
   - Affects: [which files/areas]

2. **[Improvement name]**
   - Issue: [what's wrong]
   - Impact: [why this matters]
   - Suggested fix: [specific approach]
   - Confidence: High/Medium/Low
   - Affects: [which files/areas]

3. **[Improvement name]**
   - [same format]

### Other Findings by Theme (max 15 total)

#### [Theme name] (e.g., "Testing Gaps", "Security", "Code Quality")
- [Issue] in `file:line` - [Suggested fix] - [Why] - Confidence: High/Medium/Low
- [Issue] in `file:line` - [Suggested fix] - [Why] - Confidence: High/Medium/Low

#### [Theme name]
- [Issues...]

### What to Ignore (optional - only if user might wonder about it)
[Low-value findings that aren't worth addressing - only mention if you expect the user might ask about them]
```

**Ask user:** "Which of these should we address? All top improvements? Some subset? Or is this good to ship as-is?"

Wait for user response before proceeding to implementation.

**Before implementing:**
Create beads task(s) for approved themes. See CLAUDE.md "Working in Small Steps".

---

## Implementation Workflow

**CRITICAL: Follow CLAUDE.md "Working in Small Steps" workflow**

After implementing each theme:

1. **STOP** - Do not continue to next theme
2. **Report** - Describe what changed and what tests you ran
3. **Wait** - User will say "committed" before you proceed

**Never batch multiple themes together.** ONE theme = ONE commit = ONE stop.

---

**Task-specific guidance:**

- Group approved fixes into logical themes (related changes that tell one story)
- Only fix approved items - don't add "nice-to-haves" unless asked
- If docs are extensive (>50 lines), propose changes instead of implementing

---

## What NOT to do

- Don't add features beyond the branch scope
- Don't add error handling for impossible scenarios
- Don't design for hypothetical future requirements
- Don't force root cause narratives when issues are genuinely unrelated

---

## Completion

Only after completing all phases, implementing approved changes, and updating documentation, report: "Branch optimization complete. Ready to open PR."
