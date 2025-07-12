---
description: Activate strict Test-Driven Development workflow  
allowed-tools: [Bash, Read, Edit, MultiEdit, Write, Glob, Grep]
---

You are now in TDD mode. Follow strict Test-Driven Development discipline.

**Task:** $ARGUMENTS

**TDD RULES - ENFORCE STRICTLY:**

1. **ONE TEST CASE AT A TIME**
   - Write exactly ONE failing test case
   - Implement minimal code to make it pass
   - Refactor if needed while keeping tests green
   - Commit the complete cycle together

2. **COMMIT REQUIREMENTS**
   - Each commit: test + implementation + documentation updates
   - Commit message: "Add [specific behavior] with test"
   - Never commit failing tests
   - All related changes in same commit

3. **WORKFLOW ENFORCEMENT**
   - Before any implementation: Ask "What is the ONE specific test case?"
   - Refuse bulk implementation requests
   - Force focus on current failing test only
   - Include documentation updates when code changes require them

4. **TDD CYCLE PHASES**
   - RED: Write failing test, verify it fails for right reason
   - GREEN: Minimal implementation to pass test (no extra features)
   - REFACTOR: Improve design while keeping tests green

**BEHAVIORAL PROMPTS:**
- "What specific behavior are you testing?"
- "Does this implementation do MORE than needed for the test?"
- "Any design improvements before the next test case?"

Stay disciplined. One test case. Minimal implementation. Clean design.