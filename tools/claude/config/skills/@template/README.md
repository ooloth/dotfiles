# Skill Template

This template demonstrates best practices for creating skills that follow the MCP code execution pattern described in [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp).

## When to Create a Skill

Create a skill (instead of a command or agent) when:

1. **Token-heavy operations**: The task involves fetching/processing large amounts of data
2. **Deterministic logic**: The processing doesn't require Claude's reasoning
3. **Filtering benefits**: You can filter/summarize data in code before returning to Claude
4. **Caching opportunities**: Results can be cached to avoid redundant operations
5. **Type safety matters**: Structured data with typed interfaces improves reliability

## Skills vs Agents vs Commands

| Approach | Use When | Example |
|----------|----------|---------|
| **Skill** | Heavy data processing, filtering, caching | `fetch-prs-to-review`, `analyze-codebase` |
| **Agent** | Complex exploration requiring multiple tool calls | `Explore`, `Plan`, `atomic-committer` |
| **Command** | Simple prompts that need Claude's reasoning | `/plan`, `/fix-bug` |

## How to Use This Template

### 1. Copy the Template

```bash
cp -r ~/.claude/skills/@template ~/.claude/skills/your-skill-name
```

### 2. Customize SKILL.md

Edit `SKILL.md` to define:
- **name**: How Claude will reference this skill
- **description**: When Claude should use this skill
- **allowed-tools**: Usually just `[Bash]`

Update the sections to describe your specific skill.

### 3. Implement Your Logic

In `example_skill.py` (rename to match your skill):

1. **Configuration** (lines 18-26): Update cache file names, TTLs, etc.
2. **Type Definitions** (lines 30-48): Define your data structures
3. **fetch_raw_data()** (lines 90-106): Implement your data source
4. **filter_and_process()** (lines 129-171): Filter and transform data
5. **format_markdown()** (lines 177-203): Format output for display

### 4. Test Your Skill

```bash
# Test locally first
python3 ~/.claude/skills/your-skill-name/your_script.py

# Verify caching works
python3 ~/.claude/skills/your-skill-name/your_script.py  # Should use cache
```

### 5. Document Token Savings

After implementation, measure and document:
- Tokens before (if processed via Claude tools)
- Tokens after (filtered summary)
- Percentage reduction

## Key Patterns in the Template

### Pattern 1: Cache Processed Data, Not Raw Data

```python
# ❌ Don't cache raw API responses
save_cache(raw_data)

# ✅ Do cache filtered/processed results
result = filter_and_process(raw_data)
save_cache(result.to_dict())
```

**Why**: Raw data is large. Processed data is small. Cache the small thing.

### Pattern 2: Filter in Code, Not in Claude

```python
# This filtering happens in Python (free)
active_items = [item for item in raw_data if item.get("status") == "active"]

# Not via multiple Claude tool calls (expensive in tokens)
```

**Why**: Filtering in code is essentially free. Claude tool calls cost tokens.

### Pattern 3: Sanitize Before Returning

```python
def sanitize_sensitive_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """Remove sensitive keys before returning to Claude."""
    return {k: v for k, v in data.items() if k.lower() not in SENSITIVE_KEYS}
```

**Why**: Deterministic security rules prevent accidental exposure.

### Pattern 4: Type Hints Everywhere

```python
def filter_and_process(raw_data: List[Dict[str, Any]]) -> ProcessedResult:
    """Process raw data."""
    # ...
```

**Why**: Type hints catch errors early and make code self-documenting.

### Pattern 5: User-Friendly Errors

```python
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    return 1
```

**Why**: Claude can show users helpful errors, not stack traces.

## Real-World Example

See `~/.claude/skills/fetch-prs-to-review/` for a production skill that:
- Fetches PRs from GitHub GraphQL API (~10KB response)
- Filters, groups, and formats in Python
- Returns ~2KB markdown summary
- ~80% token reduction
- Caches results with viewing history

## Checklist for New Skills

Before considering a skill complete:

- [ ] SKILL.md describes when/how to use it
- [ ] Type hints on all functions
- [ ] Caching implemented (if applicable)
- [ ] Sensitive data sanitized
- [ ] Error handling with user-friendly messages
- [ ] Output formatted for readability
- [ ] Tested locally
- [ ] Token savings measured/documented
- [ ] Script is executable (`chmod +x`)

## Further Reading

- [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) - Original article
- Claude Code docs on skills (when available)
- Your existing skills for more examples
