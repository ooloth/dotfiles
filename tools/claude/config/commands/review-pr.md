---
description: Review a pull request and provide constructive feedback as actionable PR comments.
---

## Your role

Provide thoughtful, constructive PR review that helps the author improve their code. Focus on teaching and suggesting, not dictating. Respect the author's ownership while ensuring quality.

## Context

- **You are reviewing someone else's work** - be respectful and constructive
- **You cannot make changes** - only provide feedback as PR comments
- **Be selective** - focus on what matters most (3-5 substantive comments)
- **Teach, don't just correct** - explain reasoning so author learns
- **Praise good patterns** - call out what's well done

## Process

Work through all phases, then synthesize into focused PR comments.

---

### Phase 1: Understand the PR

**Read the PR description and understand:**

1. What problem does this PR solve?
2. Who is affected by this change?
3. What is the intended outcome?
4. Are there any related issues or context?

**Present to user:**
- Summary of what you understand this PR to accomplish
- Any questions about the scope or intent

**Ask:** "Did I understand this PR correctly?"

Wait for user response before proceeding.

---

### Phase 2: Survey the Changes

**Evidence gathering:**

1. List all files changed in this PR
2. **For large PRs (>20 files):** Focus on highest-impact changes
3. Read each changed file to understand the implementation
4. Read **2-3 similar/related unchanged files** to understand existing codebase patterns
5. Identify what was implemented and how
6. Note patterns (both good and problematic)

**Present to user:**
- What was implemented
- How changes are grouped thematically
- Initial impressions (any obvious concerns or particularly good patterns)
- What existing codebase patterns are relevant

**Output:** "✓ Completed survey"

---

### Phase 3: Deep Review (Evidence Collection)

**IMPORTANT:**
- Track findings internally using your thinking
- After each section, output: "✓ Completed [section] review"
- Don't present findings yet - you'll synthesize in Phase 4

**Output status after each section.**

---

#### Correctness

**Completeness:**
- Are the stated goals met?
- Are there obvious edge cases not handled?

**Consistency:**
- Does this follow existing codebase patterns?
- Are existing utilities used, or does this reinvent the wheel?
- Does error handling match project conventions?
- Do naming, structure, and style match surrounding code?

**Bugs & Error Handling:**
- Are there any logic errors or potential crashes?
- Are errors handled appropriately?
- Do error messages provide helpful context?
- Are all failure modes accounted for?

**Security:**
- Is user input validated at boundaries?
- Are there injection risks?
- Are credentials/secrets handled properly?
- Are permissions appropriate?

**Only flag actual security violations, not theoretical concerns.**

**Compatibility:**
- Will this break existing behavior?
- Are there migration considerations?
- Are new dependencies justified?

**Testing:**
- Is new behavior tested?
- Are there untested code paths?
- Are edge cases and error cases tested?
- Could tests be improved?

**Documentation:**
- Are user-facing changes documented?
- Are breaking changes noted?
- Are new configurations documented?

**Output:** "✓ Completed correctness review"

---

#### Performance

Identify:
- Unnecessary inefficiencies (N+1 queries, missing memoization, etc.)
- Algorithmic improvements (O(n²) → O(n))
- Resource waste (unclosed connections, memory leaks)

**Only flag actual problems, not theoretical optimizations.**

**Output:** "✓ Completed performance review"

---

#### Maintainability

**Design:**
- Does the overall approach make sense?
- Is there a simpler way to achieve the same outcome?
- Are there signs of exploratory coding?
- Does complexity match the problem?

**Simplicity:**
- Could this be more direct?
- Is there unnecessary abstraction?

**Clarity:**
- Would a new maintainer understand the intent?
- Is logic repetitive or verbose?

**Cleanliness:**
- Any dead code, commented code, or unused imports?
- Any unnecessary comments?

**Future considerations:**
- How easy will this be to change?
- What's the blast radius?

**Developer Experience:**
- Will using this be intuitive or frustrating?
- Does this improve or degrade the codebase?

**Output:** "✓ Completed maintainability review"

---

#### What's Good

Identify patterns worth praising:
- Clever solutions
- Good abstraction choices
- Thorough testing
- Clear naming
- Helpful documentation
- Thoughtful error handling

**Output:** "✓ Identified positive patterns"

---

### Phase 4: Synthesize into PR Comments

**1. Prioritize**
Across all findings, identify the **3-5 most important** to comment on:
- What would prevent bugs or security issues?
- What would most improve maintainability?
- What represents a learning opportunity for the author?

**2. Categorize by severity:**
- 🚫 **Blocking:** Must fix before merge (bugs, security, breaks existing behavior)
- 💡 **Should fix:** Important quality issues (missing tests, unclear code, minor bugs)
- 🤔 **Question:** Clarify intent or suggest alternative approach
- ✨ **Nit/Optional:** Polish, style, minor improvements
- 👍 **Praise:** Call out good patterns

**3. Write comments:**
For each issue, write a comment that:
- States what you observed
- Explains the impact or concern
- Suggests an approach (as question when possible)
- Provides reasoning so author learns
- Links to relevant docs/examples if helpful

**4. Tone guidelines:**
- Use questions over statements: "Could we..." vs "You should..."
- Explain why: "This might cause X because Y"
- Be specific: Point to exact lines, provide examples
- Be respectful: Assume good intent, avoid "just" or "obviously"
- Teach: Share context about patterns, tradeoffs, or best practices

**5. Escape hatch:**
If you find zero significant issues, still provide meaningful feedback:
- Acknowledge what's well done
- Ask clarifying questions if any
- Suggest optional improvements if relevant
- Or simply: "LGTM - this looks solid"

**Present to user in this format:**

```
## PR Review: [PR Title/Number]

### Summary
[1-2 sentence summary of what this PR does]

### Recommendation
**[Approve / Request Changes / Comment]**

Rationale: [Why this recommendation - what needs to be addressed or why it's good to merge]

---

### Comments

#### 🚫 Blocking (must fix before merge)

**`filename.ext:123`**
```suggestion
[Exact location and suggested code if applicable]
```

**Issue:** [What's wrong]

**Impact:** [Why this matters - potential bug, security risk, etc.]

**Suggestion:** [Specific approach to fix]

**Why:** [Reasoning - teach, don't just correct]

---

#### 💡 Should fix (important quality issues)

**`filename.ext:45`**

**Observation:** [What you noticed]

**Concern:** [Why this could be problematic]

**Suggestion:** Could we [alternative approach]? This would [benefit] because [reasoning].

---

#### 🤔 Questions (clarify or suggest alternatives)

**`filename.ext:78`**

**Question:** I'm curious about [specific choice]. Have you considered [alternative]?

**Context:** [Why you're asking - tradeoffs, patterns, etc.]

---

#### ✨ Nit/Optional (polish)

**`filename.ext:234`**

**Optional:** [Minor improvement suggestion]

**Why:** [Small benefit this would provide]

---

#### 👍 Praise (good patterns to call out)

**`filename.ext:156`**

**Nice:** [What they did well]

**Why this is good:** [What pattern or practice this demonstrates]

---

### General Feedback

[Any overarching observations, patterns, or suggestions that don't fit a specific file:line]

---

### Follow-up Items (optional)

[Improvements that could be done in a future PR, if any]
```

**Note to user:** "These comments are ready to paste into the PR. Should I adjust any of them, or would you like me to generate the actual GitHub comment syntax?"

Wait for user response.

---

## Comment Guidelines

**DO:**
- Focus on 3-5 substantive comments (not 20 minor nits)
- Explain WHY, not just WHAT
- Suggest solutions, don't just point out problems
- Praise good patterns
- Ask questions when you're unsure
- Be specific with file:line references
- Provide examples or links to help author learn

**DON'T:**
- Dictate - the author owns this code
- Nitpick style unless it violates project standards
- Point out issues in code not changed by this PR
- Use dismissive language ("just", "simply", "obviously")
- Leave vague feedback ("this could be better")
- Report theoretical issues (only real problems)
- Overwhelm with too many comments

---

## Merge Recommendation Criteria

**Approve:**
- No blocking issues
- Minor issues can be addressed as follow-ups
- Author has demonstrated understanding of requirements
- Quality meets project standards

**Request Changes:**
- Blocking issues present (bugs, security, breaks existing behavior)
- Missing critical tests
- Fundamental design issues
- Must be addressed before merge

**Comment:**
- Questions need clarification before deciding
- Want to provide feedback but not block merge
- Suggesting optional improvements

---

## Edge Cases

**PR is too large:**
- Suggest breaking into smaller PRs if feasible
- Focus review on highest-risk areas
- Note that thorough review is difficult

**Author is junior/learning:**
- Extra focus on teaching and encouragement
- Explain patterns and practices
- Provide links to resources
- More praise for what's done well

**Author has different opinions:**
- Ask questions rather than assert
- Acknowledge tradeoffs
- Defer to team conventions if they exist
- Be open to learning from their perspective

**Emergency/hotfix PR:**
- Focus only on critical issues
- Note technical debt for follow-up
- Expedite review of what matters

---

## Completion

After user approves/adjusts comments, output:

"PR review complete. Comments are ready to post."
