---
description: Create commit with proper workflow including pre-commit checks
allowed-tools: [Bash, Read, Grep, Task]
---

Execute full commit workflow with comprehensive pre-commit checks.

**Commit scope (optional):** $ARGUMENTS

**Commit Creation Process:**

I'll use the git-workflow agent to execute the complete commit workflow including:

1. **Pre-commit checks** - formatting, linting, type checking, tests
2. **Test verification** - ensure all tests pass and coverage is complete
3. **Security check** - verify no sensitive information included
4. **Commit staging** - review changes before commit
5. **Commit message** - descriptive message explaining the change
6. **Post-commit** - verification and next steps

**Agent Delegation:**
This command automatically uses the git-workflow agent for expert Git workflow management and quality gates.