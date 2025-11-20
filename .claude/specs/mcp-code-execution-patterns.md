# MCP Code Execution Patterns - Implementation Plan

## Goal

Apply recommendations from Anthropic's "Code Execution with MCP" article to improve context efficiency, token usage, and code execution patterns in this dotfiles repository's Claude Code setup.

## Source

https://www.anthropic.com/engineering/code-execution-with-mcp

## Key Insights from Article

1. **Context Efficiency**: Filter data in code before passing to model (98.7% token reduction possible)
2. **Security**: Implement deterministic security rules for data flow
3. **Architecture**: Use code execution to process heavy operations, return only summaries
4. **Caching**: Maintain intermediate results in execution environment
5. **Typed Interfaces**: Use typed interfaces for tool interactions

## Current State

**Strengths:**
- Already using skill pattern with `fetch-prs-to-review` (exemplifies article's approach)
- Good security deny rules in `settings.json`
- Agent-based delegation for complex tasks

**Gaps:**
- Missing environment variable security rules
- No skill template to guide future skill creation
- CLAUDE.md emphasizes agents over skills for context management
- Some skills lack caching patterns
- Token-heavy commands could be converted to skills

## Implementation Themes

### Theme 1: Environment Variable Security Rules ✅
**Files**: `tools/claude/config/settings.json`

Add deterministic security rules to deny patterns that could leak secrets:
- `Bash(:*AWS_SECRET:*)`
- `Bash(:*GH_TOKEN:*)`
- `Bash(:*ANTHROPIC_API_KEY:*)`
- `Bash(export :*_TOKEN=:*)`
- `Bash(export :*_KEY=:*)`
- `Bash(export :*_SECRET=:*)`

### Theme 2: Skill Template ✅
**Files**: `tools/claude/config/skills/@template/`

Create a reference template showing best practices:
- SKILL.md with structure similar to fetch-prs-to-review
- Example Python script with:
  - Type hints
  - Data filtering before output
  - Caching patterns
  - Error handling
  - Comments explaining the pattern

### Theme 3: Context Management Strategy Update ✅
**Files**: `tools/claude/config/CLAUDE.md`

Update "Managing your context window" section to prioritize:
1. Skills (code-based processing) - first choice
2. Agents (complex exploration) - second choice
3. Direct tool usage - last resort

Add guidance on:
- When to create a skill vs use an agent
- Skill design principles (filter in code, cache results, return summaries)
- Type hints and error handling expectations

### Theme 4: Enhanced Caching for Existing Skills ✅
**Files**: `tools/claude/config/skills/*/`

Review and enhance caching in:
- `fetch-prs-to-review`: Already good, document as example
- `inspect-codefresh-failure`: Add caching for build logs by build_id
- Future skills: Apply caching template

## Non-Goals

- Converting all commands to skills (some need Claude's reasoning)
- Removing agent delegation (still valuable for exploration)
- Over-engineering skills with unnecessary abstraction

## Success Criteria

- [ ] Security rules prevent common secret exposure patterns
- [ ] Template exists showing MCP best practices
- [ ] CLAUDE.md clearly guides skill-first approach
- [ ] Existing skills demonstrate caching patterns
- [ ] Pattern is reusable for future skill creation

## Hand-off Notes

Each theme should be implemented and committed separately to maintain atomic commits.
