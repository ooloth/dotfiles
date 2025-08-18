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

- **atomic-committer**: MANDATORY for ALL git commit operations
- **pr-creator**: MANDATORY for creating PR descriptions (maintains opinionated templates)
- **type-error-fixer**: MANDATORY for fixing all type errors

### Slash Commands: Optional Systematic Approaches

**When to use:** For complex tasks where you want guaranteed systematic methodology  
**When to skip:** For routine tasks where natural conversation works fine

**REVIEW Commands** (Systematic analysis when you need thoroughness)

- `/review-code` - Comprehensive quality audit across all dimensions (bugs, architecture, security, performance, tests, readability, modern patterns)
- `/review-pr [number]` - Structured PR review process (defaults to current branch if no number given)

**FIX Commands** (Methodical problem resolution)

- `/fix-bug` - 6-step systematic debugging process
- `/fix-code` - Comprehensive code improvement (architecture, performance, security, quality)
- `/fix-types` - Domain-driven type design and safety improvements
- `/fix-tests` - Test creation, improvement, and coverage enhancement
- `/fix-docs` - Documentation creation and improvement

**PLANNING** (Structured decision making)

- `/plan` - 4-phase problem analysis framework

### GitHub-First Project Organization

**✅ GOOD: Systematic Issue Breakdown**

```
Epic: Add Dark Mode Support (#100)
├── #101: Create theme context and provider
├── #102: Add theme toggle component
├── #103: Update color system for dark variants
├── #104: Migrate existing components to use theme
└── #105: Add theme persistence and system detection
```

**❌ BAD: Monolithic Epic Description**

```
Epic: Add Dark Mode Support (#100)
- Implement theme switching
- Update colors
- Fix components
- Add persistence
[All details buried in epic description]
```

**BENEFITS OF ISSUES-FIRST APPROACH:**

- **Immediate pickup**: Any Claude can start work without research
- **Parallel development**: Multiple issues can be worked simultaneously
- **Clear progress**: Visual tracking through GitHub interface
- **Automatic linking**: PRs automatically reference and close issues
- **Session continuity**: No archaeological research needed

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
