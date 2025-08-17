# Claude Code Configuration Guide

This directory contains a streamlined Claude Code configuration optimized for natural conversation with optional systematic approaches.

## Core Philosophy: Natural Conversation + Optional Power Tools

### Primary Workflow: Natural Conversation

**Default approach**: Simply describe what you need in natural language.

```
"Fix this authentication bug"
"Review my pull request"
"Implement user login functionality"
"Help me optimize this slow query"
```

**Why this works:**

- Claude brings fresh perspective without preconceived constraints
- Full context awareness for better decision-making
- Natural problem-solving flow
- No cognitive overhead about "the right way" to ask

**Trade-offs:**

- ✅ Most flexible and intuitive
- ✅ Claude can see solutions you might not consider
- ✅ Fastest for routine tasks
- ⚠️ Approach may vary between conversations
- ⚠️ No guaranteed systematic coverage for complex tasks

### Secondary Workflow: Slash Commands (Power Tools)

**When to use**: For complex tasks where you want guaranteed systematic methodology.

```
/fix-bug "authentication failing intermittently"
/plan "implement user authentication system"
/review-quality auth.py
```

**Why slash commands exist:**

- Proven methodologies for complex scenarios
- Ensure nothing gets missed in systematic analysis
- Consistent approach across conversations
- Battle-tested frameworks for debugging, planning, reviewing

**Trade-offs:**

- ✅ Guaranteed systematic coverage
- ✅ Consistent methodology every time
- ✅ Comprehensive for complex tasks
- ⚠️ More verbose than needed for simple tasks
- ⚠️ May feel rigid for exploratory work

## Decision Framework: When to Use Each

### Use Natural Conversation When:

- **Exploring solutions** - "How should I implement this?"
- **Routine tasks** - "Add error handling to this function"
- **Quick fixes** - "This test is failing"
- **Brainstorming** - "What are my options for user authentication?"
- **You trust Claude's judgment** - Most scenarios

### Use Slash Commands When:

- **Complex debugging** - `/fix-bug` for systematic 6-step process
- **Important reviews** - `/review-quality` for comprehensive audit
- **Strategic planning** - `/plan` for 4-phase analysis framework
- **You know the methodology helps** - Based on past experience
- **Nothing can be missed** - Critical or high-stakes scenarios

## Specialist Agent Architecture

The system includes focused specialists that main Claude consults when beneficial:

### High-Value Specialists (Context isolation provides clear benefit)

- **`git-workflow`** - MANDATORY for git operations (syntax precision)
- **`pr-creator`** - Maintains your opinionated PR templates (AUTOMATICALLY used by git-workflow)
- **`design-architect`** - Complex architecture/security/performance analysis
- **`researcher`** - "What's the best X?" questions + technology preferences
- **`task-manager`** - Multi-PR coordination and GitHub issue tracking

### Critical: PR Description Enforcement

**Problem**: Claude often writes generic PR descriptions instead of using your template
**Solution**: git-workflow agent automatically delegates to pr-creator for ALL PR creation
**If this breaks again**: The git-workflow agent has multiple fail-safes to prevent this

### Why Some Agents Were Removed

- **`test-designer`** - Testing benefits from full system context
- **`data-analyst`** - Debugging needs complete understanding
- **`software-engineer`** - Coordination overhead outweighed benefits
- **`problem-solver`** - Main Claude handles this naturally

## Technology Preferences

Preferences are embedded in the `researcher` agent's fast-path responses:

**Python**: `uv` > pip/poetry, `ruff` > black/flake8, `pytest` + `pytest-cov`
**JavaScript**: `pnpm` > npm/yarn, `vitest` > jest (new projects), TypeScript by default
**Go**: Standard library first, minimal dependencies
**Rust**: `cargo` + `clippy` + `rustfmt`

These are applied automatically when Claude consults researcher for "which tool should I use?" questions.

## Design Intentions

### For Users

- **Remove cognitive load** - No "right way" to ask
- **Preserve power when needed** - Systematic approaches available
- **Natural workflow** - Conversation feels normal
- **Reliable outcomes** - Good practices built-in
- **Planning-first fixes** - All `/fix-*` commands start with strategy assessment

### For Future Claude Development

- **Natural conversation is primary** - Don't force users into commands
- **Slash commands preserve methodology** - Don't dilute systematic approaches
- **Specialists provide clear value** - Only keep agents that work better in isolation
- **Technology preferences stay current** - Update researcher agent, not giant CLAUDE.md

## Common Patterns

### Debugging Workflow

```
Natural: "This test is failing with a timeout error"
→ Claude investigates and fixes naturally

Power: "/fix-bug authentication test timeout"
→ 6-step systematic debugging process
```

### Code Review Workflow

```
Natural: "Review this PR"
→ Claude does thorough review with context

Power: "/review-pr #123"
→ Structured 4-phase review process
```

### Planning Workflow

```
Natural: "How should I implement user sessions?"
→ Claude suggests approaches naturally

Power: "/plan user session management"
→ 4-phase systematic analysis framework
```

## Evolution Guidelines

When modifying this system:

1. **Preserve the core philosophy** - Natural conversation primary, slash commands optional
2. **Add specialists judiciously** - Only when context isolation provides clear benefit
3. **Keep methodologies in commands** - Don't move systematic frameworks back to agents
4. **Update technology preferences in researcher** - Not in main CLAUDE.md
5. **Test both workflows** - Ensure natural and systematic approaches both work

## File Organization

```
home/.claude/
├── CLAUDE.md           # Core workflow philosophy and behaviors
├── README.md           # This guide (system intentions and usage)
├── agents/             # Specialist agents for focused expertise
│   ├── design-architect.md
│   ├── git-workflow.md
│   ├── pr-creator.md
│   ├── researcher.md
│   └── task-manager.md
└── commands/           # Slash commands with systematic methodologies
    ├── plan.md         # 4-phase problem analysis
    ├── fix-bug.md      # 6-step debugging process
    ├── fix-code.md     # Comprehensive code improvement
    ├── fix-types.md    # Domain-driven type design
    ├── fix-tests.md    # Test creation and improvement
    ├── fix-docs.md     # Documentation creation and improvement
    ├── review-code.md  # Comprehensive quality audit
    └── review-pr.md    # PR review process
```

---

**Remember**: Start with natural conversation. Use slash commands when you want guaranteed systematic coverage. Both approaches lead to good outcomes, but with different characteristics. Choose based on the situation and your preferences.

