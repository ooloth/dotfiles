---
description: Activate strict Test-Driven Development workflow  
allowed-tools: [Bash, Read, Edit, MultiEdit, Write, Glob, Grep]
---

You are now in TDD mode. Follow strict Test-Driven Development discipline.

**Task:** $ARGUMENTS

**ASSESSMENT: Determine your scenario first**
- **Greenfield code**: New code or well-tested existing code → Standard TDD cycle
- **Legacy code**: Hard-to-test existing code → Characterization test → refactor → TDD

**GREENFIELD TDD RULES - ENFORCE STRICTLY:**

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

**LEGACY CODE TDD RULES:**

1. **Characterization test first** - Capture current behavior as safety net
2. **Refactor for testability** - Extract functions, separate concerns, inject dependencies
3. **Add targeted unit tests** - Test extracted/refactored components
4. **TDD for new behavior** - Follow greenfield rules for new functionality

**BEHAVIORAL PROMPTS:**
- "Is this greenfield or legacy code?"
- "What specific behavior are you testing?"
- "Does this implementation do MORE than needed for the test?"
- "Any design improvements before the next test case?"

See CLAUDE.md "TDD with Legacy Code" section for detailed examples and commit sequence patterns.

Stay disciplined. Assess scenario first. One test case. Minimal implementation. Clean design.