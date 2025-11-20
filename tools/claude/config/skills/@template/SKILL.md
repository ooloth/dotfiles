---
name: skill-name
description: Brief description of what this skill does. Should be clear enough that Claude knows when to invoke it.
allowed-tools: [Bash]
---

# Skill Name

One-paragraph description of what this skill does and when to use it.

## MCP Code Execution Pattern

This skill follows the pattern described in [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp):

1. **Heavy processing in code** - Fetch/process data in Python/bash, not via Claude tools
2. **Filter before returning** - Return only relevant summaries, not raw data
3. **Cache intermediate results** - Avoid redundant API calls or expensive operations
4. **Use typed interfaces** - Type hints for reliability and clarity
5. **Deterministic security** - Never expose sensitive data in output

## Usage

How Claude should invoke this skill:

```bash
python3 ~/.claude/skills/skill-name/script.py [optional-args]
```

Or if using bash:

```bash
bash ~/.claude/skills/skill-name/script.sh [optional-args]
```

## What It Returns

Describe the output format. For example:

- Returns formatted markdown ready to display
- Returns JSON for programmatic processing
- Returns exit code 0 on success, 1 on error
- Outputs to stdout (results) and stderr (errors/warnings)

Example output:

```
# Example Output

Summary: Processed 42 items in 1.2s

Details:
- Item 1: Status OK
- Item 2: Status WARNING (details...)

Next steps: [recommendations]
```

## Processing Done by Skill

List the steps this skill performs in code (not in Claude):

1. Fetch data from source (API, filesystem, command output)
2. Filter/transform data using business logic
3. Calculate derived metrics or summaries
4. Cache results for subsequent invocations
5. Format output for readability
6. Return only essential information

## Implementation Details

### Caching Strategy

- **Cache location**: `~/.claude/.cache/skill-name.json`
- **Cache invalidation**: Describe when cache is cleared/updated
- **Cache structure**: Describe what data is cached and why

### Error Handling

- Exits with code 1 on errors
- Prints user-friendly error messages to stderr
- Falls back to sensible defaults when possible
- Never crashes silently

### Dependencies

List any external dependencies:
- Python 3.x required
- Standard library modules: `json`, `subprocess`, `datetime`
- External tools: `gh` CLI, `curl`, etc.
- API requirements: GitHub token, etc.

## Design Rationale

### Why a Skill vs Agent?

This operation is ideal for a skill because:
- Heavy data processing that would consume many tokens if done via Claude tools
- Deterministic logic that doesn't require Claude's reasoning
- Results can be pre-filtered and summarized
- Caching provides significant performance benefits

### Token Efficiency

Estimated token savings compared to using Claude tools directly:
- Before: ~X tokens (raw data + processing)
- After: ~Y tokens (formatted summary)
- Reduction: ~Z% token savings

## Future Enhancements

Ideas for extending this skill:
- Additional output formats
- More filtering/sorting options
- Integration with other tools
- Performance optimizations
