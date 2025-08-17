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

- **`atomic-committer`** - Creates small, thematic git commits
- **`pr-creator`** - Writes PR descriptions in your opinionated style
- **`researcher`** - "What's the best X?" questions + technology preferences

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
└── commands/           # Slash commands with systematic methodologies
```

---
