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
2. **Follow best practices naturally** - Test-first development, documentation updates, task management updates

**High-Value Specialists (use when beneficial):**

- **atomic-committer**: MANDATORY for ALL git commit operations
- **pr-creator**: MANDATORY for creating PR descriptions (maintains opinionated templates)
- **researcher**: for large file or web search tasks where a clear question and answer can be formulated
- **type-error-fixer**: MANDATORY for fixing all type errors

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
