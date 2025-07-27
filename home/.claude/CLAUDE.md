## Core Principle: Delegate to Expert Agents and Commands

### Development Workflow: Use Agents for Everything

**STREAMLINED: Main Claude handles implementation, coordination, and communication. Consult specialists for deep expertise when beneficial.**

**Specialist Agents (consult when beneficial):**
- **design-architect**: For architecture, security, and performance analysis - deep expertise for secure, performant design
- **test-designer**: For test planning, strategy, execution, and coverage - specialized testing expertise  
- **researcher**: For documentation lookup, API research, and best practices investigation
- **data-analyst**: For data processing optimization, DataFrame operations, and database performance
- **git-workflow**: For ALL git operations - commits, branches, PRs, merges, pushes, pulls (NEVER perform git operations manually)
- **pr-writer**: For commit messages and PR descriptions (maintains consistent templates and formatting)
- **task-manager**: For multi-PR coordination and GitHub issue tracking

### Slash Commands for Structured Workflows

**Discovery pattern:** Type `/review-[TAB]`, `/create-[TAB]`, `/fix-[TAB]`, or use `/plan`

**REVIEW-*** (Analysis & Verification)
- `/review-code` - Direct expert consultation for comprehensive code quality review
- `/review-security` - Security vulnerability assessment via design-architect
- `/review-performance` - Performance analysis via design-architect
- `/review-architecture` - Design and architecture evaluation via design-architect
- `/review-tests` - Test execution and coverage verification via test-designer
- `/review-pr [url]` - Pull request review with direct expert consultation
- `/review-quality` - Combined quality audit via coordinated expert consultation

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

**PLANNING (Strategy & Design)
- `/plan` - Intelligent problem analysis with expert coordination for any domain

### Git Operations Delegation Rules

**MANDATORY: All git operations MUST be delegated to git-workflow agent:**
- **"commit"**, **"push"**, **"pull"**, **"merge"** → Always use git-workflow agent
- **"merge pr"**, **"merge pull request"**, **"merge the pr"** → Always use git-workflow agent  
- **"branch"**, **"checkout"**, **"rebase"** → Always use git-workflow agent
- **ANY GitHub CLI operations** (gh pr merge, gh pr create, etc.) → Always use git-workflow agent

**Never perform git operations manually with direct tool calls.**

### Code Review Strategy: Direct Expert Consultation

**STREAMLINED REVIEW PROCESS: Skip intermediary agents, consult experts directly**

**For comprehensive code reviews:**
1. **Direct specialist consultation** - Delegate to relevant experts simultaneously:
   - **design-architect**: Architecture, security, and performance review
   - **test-designer**: Test coverage and quality assessment
   - **Documentation updates**: When code changes affect user workflows or APIs
   - **data-analyst**: Data processing optimization (when applicable)
2. **Provide complete context** - Give each specialist the full context they need
3. **Synthesize feedback** - Combine insights from parallel consultations
4. **Present unified review** - Coherent feedback with specialist attribution

**Benefits of direct consultation:**
- **3x faster**: No intermediary agent overhead
- **More reliable**: Direct specialist expertise without interpretation layers
- **Better coverage**: Parallel specialist analysis catches more issues
- **Cleaner process**: Streamlined workflow with immediate expert access

### Expert Coordination Strategy

**PARALLEL CONSULTATION (for complex problems):**
1. **Identify all needed specialists** upfront
2. **Launch simultaneous consultations** with complete context
3. **Enable cross-referencing** between specialist responses
4. **Synthesize insights** as responses arrive

**Benefits:** 3x faster than sequential consultation, better solution quality, comprehensive coverage

**Use parallel consultation when:**
- Problem spans multiple domains (architecture + testing + performance)
- Complex trade-offs require specialized input
- Time-sensitive decisions need comprehensive analysis

### Key Behavioral Changes

**Default Good Practices (Built into All Agents):**
- Tests created alongside implementation (not before/after)
- Logical commit units: test + implementation + docs together
- Behavioral testing (test what code does, not how)
- Documentation updates with code changes
- Descriptive commit messages explaining the change

**Quality Gates (before each commit):**
- All tests pass (existing + new)
- Code follows project style guidelines
- No obvious performance issues
- Documentation is current
- Commit represents complete behavior

**Atomic Commit Composition:**
- One test case + its implementation + related docs
- Complete, working functionality for that behavior
- Clear commit message explaining the behavior added
- No breaking changes to existing functionality

### Documentation Standards

**README.md vs CLAUDE.md Distinction:**
- **README.md**: General project info, installation, usage examples (for all users)
- **Project CLAUDE.md**: Claude-specific guidance, file paths, project workflows (minimal, accurate)

**Critical Requirements:**
- **Always verify file paths exist** before referencing in documentation
- Use directory listing to check actual file names - don't assume conventions
- Test commands before documenting them
- Update docs in same commit as related code changes

**Documentation Hierarchy:**
1. README.md - Primary project documentation
2. Project CLAUDE.md - Claude-specific guidance only
3. Code comments - Explain non-obvious decisions
4. API docs - Technical reference

**Permissions:**
Auto-approved commands in `~/.claude/settings.json` - use directly without asking.

**Project Guidelines:**
See project-specific CLAUDE.md files for additional local guidance.