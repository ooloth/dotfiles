## Workflow Philosophy: Natural Conversation with Optional Power Tools

### For Users: How to Work with Claude

**Primary Approach: Natural Conversation**
- Simply describe what you need: "fix this bug", "implement user auth", "review my code"
- Claude follows best practices automatically and consults specialists when valuable
- No need to memorize commands or worry about "the right way" to ask

**Slash Commands: Optional Power Tools**
- Use when you want guaranteed systematic methodology
- Helpful for complex tasks: `/plan` for big decisions, `/fix-bug` for tricky debugging  
- Think of them as "expert mode" - same outcome, more structured process

### For Claude: How to Handle Requests

**Default Behavior:**
1. **Handle implementation directly** - You're the primary coordinator
2. **Follow best practices naturally** - Test-first development, atomic commits, documentation
3. **Consult specialists when valuable** - Don't delegate unnecessarily
4. **Apply technology preferences** - Via specialist fast-path knowledge

**High-Value Specialists (use when beneficial):**
- **git-workflow**: MANDATORY for ALL git operations (commits, branches, PRs, merges)
- **pr-writer**: For commit messages and PR descriptions (maintains opinionated templates)
- **design-architect**: For complex architecture, security, and performance analysis
- **researcher**: For "what's the best X?" questions and documentation lookups
- **task-manager**: For multi-PR coordination and GitHub issue tracking

### Slash Commands: Optional Systematic Approaches

**When to use:** For complex tasks where you want guaranteed systematic methodology  
**When to skip:** For routine tasks where natural conversation works fine

**REVIEW Commands** (Systematic analysis when you need thoroughness)
- `/review-code` - Comprehensive quality audit across all dimensions (bugs, architecture, security, performance, tests, readability, modern patterns)
- `/review-pr [number]` - Structured PR review process (defaults to current branch if no number given)

**CREATE Commands** (Structured creation workflows)
- `/create-tests` - Systematic test design and implementation
- `/create-docs` - Comprehensive documentation creation
- `/create-branch` → Delegates to git-workflow agent
- `/create-commit` → Delegates to git-workflow agent
- `/create-pr` → Delegates to git-workflow agent

**FIX Commands** (Methodical problem resolution)
- `/fix-bug` - 6-step systematic debugging process
- `/fix-performance` - Structured optimization workflow
- `/fix-security` - Systematic vulnerability remediation
- `/fix-tests` - Methodical test failure resolution
- `/fix-architecture` - Structural design improvements
- `/fix-types` - Type safety and annotation improvements
- `/fix-quality` - General code quality enhancements

**PLANNING** (Structured decision making)
- `/plan` - 4-phase problem analysis framework

### Git Operations Delegation Rules

**MANDATORY: All git operations MUST be delegated to git-workflow agent:**
- **"commit"**, **"push"**, **"pull"**, **"merge"** → Always use git-workflow agent
- **"merge pr"**, **"merge pull request"**, **"merge the pr"** → Always use git-workflow agent  
- **"branch"**, **"checkout"**, **"rebase"** → Always use git-workflow agent
- **ANY GitHub CLI operations** (gh pr merge, gh pr create, etc.) → Always use git-workflow agent

**Never perform git operations manually with direct tool calls.**

**CRITICAL: PR descriptions MUST use pr-writer agent**
- git-workflow agent automatically delegates to pr-writer for ALL PR descriptions
- User's template (.github/PULL_REQUEST_TEMPLATE.md) must be used exactly
- Generic Claude PR descriptions are forbidden - this has been debugged dozens of times

### Code Review Strategy: Direct Expert Consultation

**STREAMLINED REVIEW PROCESS: Skip intermediary agents, consult experts directly**

**For comprehensive code reviews:**
1. **Direct specialist consultation** - Delegate to relevant experts when beneficial:
   - **design-architect**: Architecture, security, and performance review
   - **researcher**: Best practices and documentation verification
   - **Documentation updates**: When code changes affect user workflows or APIs
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