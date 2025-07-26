## Core Principle: Delegate to Expert Agents and Commands

### Development Workflow: Use Agents for Everything

**CRITICAL: Default to agent delegation for ALL operations. Manual execution should be the rare exception, not the default.**

**Primary Agents (use proactively):**
- **software-engineer**: For coordinated feature implementation, refactoring, and coding tasks (collaborates with design-architect, test-designer, git-workflow, researcher, and data-analyst)
- **code-reviewer**: After writing/modifying code
- **design-architect**: For architecture decisions and patterns (consults researcher for best practices)
- **debugger**: For errors, bugs, and troubleshooting (consults data-analyst for data issues, researcher for framework problems)
- **test-designer**: For test planning and strategy (consults researcher for testing frameworks)
- **test-runner**: For test execution and coverage
- **security-auditor**: For security analysis (consults researcher for security best practices)
- **performance-optimizer**: For performance improvements (consults data-analyst for data performance)
- **researcher**: For documentation lookup, API research, and best practices investigation
- **data-analyst**: For data processing optimization, DataFrame operations, and database performance
- **git-workflow**: For ALL git operations - commits, branches, PRs, merges, pushes, pulls (NEVER perform git operations manually)
- **pr-writer**: For commit messages and PR descriptions
- **doc-maintainer**: For documentation updates
- **task-manager**: For multi-PR coordination

### Slash Commands for Structured Workflows

**Discovery pattern:** Type `/review-[TAB]`, `/create-[TAB]`, `/fix-[TAB]`, or `/plan-[TAB]`

**REVIEW-*** (Analysis & Verification)
- `/review-code` - Comprehensive code quality review
- `/review-security` - Security vulnerability assessment  
- `/review-performance` - Performance analysis
- `/review-architecture` - Design and architecture evaluation
- `/review-tests` - Test execution and coverage verification
- `/review-pr [url]` - Pull request review
- `/review-quality` - Combined quality audit (code + security + performance)

**CREATE-*** (Generate & Build)
- `/create-tests` - Design and implement test suite
- `/create-docs` - Create/update documentation
- `/create-branch` - New Git branch with proper naming
- `/create-commit` - Full commit workflow with checks
- `/create-pr` - Draft pull request creation

**FIX-*** (Solve & Improve)
- `/fix-bug` - Systematic debugging and resolution
- `/fix-performance` - Performance optimization
- `/fix-security` - Security vulnerability fixes
- `/fix-tests` - Test failure resolution
- `/fix-code` - Code quality improvements and refactoring

**PLAN-*** (Strategy & Design)
- `/plan-feature` - Architecture and test strategy for new features
- `/plan-refactor` - Refactoring strategy and approach

### Git Operations Delegation Rules

**MANDATORY: All git operations MUST be delegated to git-workflow agent:**
- **"commit"**, **"push"**, **"pull"**, **"merge"** → Always use git-workflow agent
- **"merge pr"**, **"merge pull request"**, **"merge the pr"** → Always use git-workflow agent  
- **"branch"**, **"checkout"**, **"rebase"** → Always use git-workflow agent
- **ANY GitHub CLI operations** (gh pr merge, gh pr create, etc.) → Always use git-workflow agent

**Never perform git operations manually with direct tool calls.**

### Key Behavioral Changes

**Default Good Practices (Built into All Agents):**
- Tests created alongside implementation (not before/after)
- Logical commit units: test + implementation + docs together
- Behavioral testing (test what code does, not how)
- Documentation updates with code changes
- Descriptive commit messages explaining the change

**Permissions:**
Auto-approved commands in `~/.claude/settings.json` - use directly without asking.

**Project Guidelines:**
See project-specific CLAUDE.md files for additional local guidance.