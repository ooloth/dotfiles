---
name: review-branch
description: Look for opportunities to optimize the approach and/or implementation of the solution to a problem you see on the current branch (relative to its base branch). Use when the user asks you to assess, analyze, improve, optimize, review or validate the current branch or its changes.
allowed-tools: Bash Read Grep Glob
effort: high
model: opus
---

## Your role

Protect users of this software by scrutinizing it closely before it ships. Focus on strategic insight, not just thorough auditing.

## Process

**Work through ALL phases below in order.** Catch fundamental issues early (Phase 1), collect evidence silently (Phases 2-4), then present a synthesized, prioritized picture (Phase 5).

**Context budget:** Your context window must last the full session — Phase 1 (lean survey), Phases 2-4 (subagents do all file reading), Phase 5 (synthesize subagent outputs), then one or more implementation rounds where the user asks you to fix approved items. Spend context at synthesis time, not during information gathering. If you exhaust your context before implementation begins, you become useless at the moment you're needed most.

---

### Phase 1: Understand & Survey

**CRITICAL: Do NOT read file contents in the main agent during this phase. All file reading happens inside review-code's 10 parallel agents (Phases 2-4). Reading files here exhausts your context before the review begins.**

**Gather fast signals only (no file reads):**

1. Read commit messages: `git log <base>...HEAD --format="%s%n%b"` — intent and approach
2. Run `git diff <base>...HEAD --stat` — changed files, directories, and scale
3. Check trekker task list if available for linked requirements

**From those signals, present to user:**

- **Problem:** what pain point this addresses and who experiences it
- **Outcome:** what success looks like; any simpler alternative you can see
- **Reversibility:** one-way door (data schemas, public APIs, core UX) or two-way door
- **Change themes:** files grouped by directory/concern (feature logic, tests, migrations, config, etc.)
- **Scale:** file count, rough line totals, number of commits
- **Initial hypothesis:** any fundamental red flags visible from commit messages + file names alone (e.g., "Commit messages suggest this reimplements X that already exists", "File names suggest an approach that conflicts with pattern Z")

**Ask for confirmation:** "Did I understand the problem and approach correctly?"

Wait for user response, then — regardless of what the user says — construct the context block below and proceed immediately to Phases 2-4.

**Construct a structured context block for review-code** (do this after the user confirms, before invoking the skill):

```
Problem: [one sentence — what was broken or missing]
Approach: [one sentence — how this change addresses it]
Key outcomes: [bullet list — invariants, constraints, requirements the implementation must satisfy]
Change themes: [bullet list — file groups and what each does]
Key questions to investigate: [bullet list — specific risks or areas derived from commit messages,
  e.g. "Migration rewrites rows in-place: check for partial-run safety and concurrent access",
  "State machine is the TOCTOU guard: verify FOR UPDATE lock actually closes the window",
  "New enum shares the DB table with old values: check all ORM→domain casts are validated"]
Diff command: git diff <base>...HEAD
```

The "Key questions" section is the most important part — it transforms generic checklists into targeted, domain-aware reviews. Derive it from what the commit messages explicitly flag as risky or novel.

**Redesign scope boundary:** If a redesign would require touching >100 lines or >5 files, note it as design debt but don't block this PR.

---

### Phases 2-4: Deep Review

**Invoke Skill(review-code)**, passing:

- **Files:** the changed files list from Phase 1
- **How to read them:** local file paths (files are on disk)
- **Context:** the problem statement, desired outcome, change themes, and initial hypothesis from Phase 1

The `review-code` skill performs a full read of all changed files and 2-3 related unchanged files,
loads relevant conventions, and runs correctness, performance, and maintainability analysis —
noting positive findings throughout.

---

### Phase 5: Synthesis & Prioritization

Map review-code's neutral findings to the branch review format and connect the dots.

**Before organizing findings, calibrate them against your Phase 1 domain knowledge:**
- Dismiss false positives that don't apply given the context (e.g., a "missing error handler" finding on code that intentionally propagates, a "performance concern" on a path that runs once per deploy)
- Elevate findings that are especially risky given the domain constraints you identified (e.g., GxP audit trail gaps, migration safety, security boundaries, irreversible operations)
- If a subagent finding contradicts something the commit messages explicitly addressed, note that the finding may be stale and flag it as low-confidence
- Do NOT read any files to resolve ambiguity — if a finding is uncertain, report it with Low confidence and let the user decide

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
   - Tradeoffs: Value — [what it unlocks] / Cost — [complexity, maintenance] / Risk — [what breaks if wrong] / Alternative — [what was considered and rejected] *(omit if not an architectural decision)*
   - Reversibility: one-way door / two-way door *(omit if not an architectural decision)*
   - Confidence: High/Medium/Low
   - Affects: [which files/areas]

2. **[Improvement name]**
   - Issue: [what's wrong]
   - Impact: [why this matters]
   - Suggested fix: [specific approach]
   - Tradeoffs: *(omit if not an architectural decision)*
   - Reversibility: *(omit if not an architectural decision)*
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
Create trekker task(s) for approved themes. See CLAUDE.md "Working in Small Steps".

---

### Phase 6: Completeness Check

**Do NOT read any files in this phase.** Draw completeness conclusions entirely from what Phase 5's synthesis already contains.

Ask yourself — from what the subagents reported:

1. **Goal achieved?** Did the findings suggest the stated problem from Phase 1 is actually solved, or are there gaps that undercut it?
2. **Edge cases?** Did any agent flag unhandled inputs, states, or sequences? If so, those are your completeness gaps.
3. **Test coverage?** Did the test-quality agent surface missing cases on critical paths?
4. **Manual validation?** Did any agent confirm or question whether the codepath was actually exercised end-to-end?

**Present to user:** Two or three sentences alongside Phase 5 — what's demonstrably complete, and what (if anything) the review couldn't confirm. If the subagents didn't surface completeness concerns, say so and move on.

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
