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
| **Skill** | Heavy data processing, filtering, caching | `fetching-github-prs-to-review`, `analyzing-codebase` |
| **Agent** | Complex exploration requiring multiple tool calls | `Explore`, `Plan`, `atomic-committer` |
| **Command** | Simple prompts that need Claude's reasoning | `/plan`, `/fix-bug` |

## Naming Conventions

Follow these naming rules from [Claude Docs Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

### Skill Name (frontmatter)

**Pattern: gerund + noun** (action + domain)

- ✅ Good: `fetching-github-prs-to-review`, `analyzing-python-code`, `inspecting-codefresh-failures`
- ❌ Bad: `helper`, `utils`, `github-tool`

**Why gerund first:**
- Smaller list of actions (~10-20) than domains (~20-50+)
- Groups related actions together when alphabetically sorted
- Natural English reading (verb phrase)

**Examples by action:**
```
analyzing-python-code
analyzing-javascript-code
analyzing-terraform-plans

fetching-github-prs-to-review
fetching-jira-tickets
fetching-slack-messages

inspecting-codefresh-failures
inspecting-docker-logs
inspecting-kubernetes-pods
```

### Skill Description (frontmatter)

- **Third person**: "Fetches and processes..." (not "I fetch...")
- **Specific functionality**: Include key terms Claude will recognize
- **Max 1024 characters**: Be concise but clear
- **When to invoke**: Make it obvious when Claude should use this skill

**Example:**
```yaml
description: Fetches GitHub pull requests waiting for review, filters by criteria, groups by category, and returns formatted markdown with CI status, review state, and priority ordering. Use when user wants to see their PR review queue.
```

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

## Anti-Patterns to Avoid

From [Claude Docs Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

### ❌ Windows-Style File Paths

```python
# ❌ Don't use backslashes
path = "C:\\Users\\name\\file.txt"

# ✅ Use forward slashes (works on all platforms)
path = "C:/Users/name/file.txt"
# Or better: use pathlib
from pathlib import Path
path = Path.home() / "file.txt"
```

### ❌ Too Many Options

```python
# ❌ Don't create decision paralysis
def analyze(format='json', sort='asc', limit=10, group_by=None,
            filter_by=None, include_meta=True, verbose=False):
    # Too many choices!

# ✅ Provide sensible defaults, minimal required params
def analyze(data: List[Dict], output_format: str = 'markdown'):
    # Simple, clear interface
```

### ❌ Assuming Package Installations

```yaml
# ❌ Don't assume packages exist
dependencies:
  - requests  # Might not be installed!

# ✅ List requirements AND check availability
dependencies:
  - requests (required): pip install requests
  - jq (optional): brew install jq
```

In code:
```python
try:
    import requests
except ImportError:
    print("Error: requests not installed. Run: pip install requests", file=sys.stderr)
    sys.exit(1)
```

### ❌ Time-Sensitive Information

```markdown
# ❌ Don't hardcode dates or versions
Last updated: January 2025
Tested with Claude Sonnet 4.0

# ✅ Use relative time or omit
Updated regularly
Compatible with current Claude models
```

### ❌ Deep File References

```markdown
# ❌ Don't nest references too deep
See references/detailed/workflows/advanced/patterns.md

# ✅ Keep references one level from SKILL.md
See references/workflow-patterns.md
```

**Why**: Claude loads files on-demand. Deep nesting increases context load and makes navigation confusing.

## Development Process

Recommended workflow from [Claude Docs Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

### 1. Complete Task Without Skill First

Before creating a skill, manually complete the task using Claude tools. This helps you:
- Understand the actual workflow
- Identify token-heavy operations
- Spot patterns worth automating
- Validate the use case

### 2. Identify Reusable Patterns

Ask yourself:
- What parts are deterministic? (good for code)
- What parts need Claude's reasoning? (keep in workflow)
- What data can be filtered in code? (token savings)
- What results can be cached? (performance)

### 3. Create Initial Skill

Start with the template:
```bash
cp -r ~/.claude/skills/@template ~/.claude/skills/action-domain
```

Focus on:
- Clear workflow in SKILL.md
- Working script (even if simple)
- Basic error handling

### 4. Test with Different Claude Models

If available, test your skill with:
- Haiku (fast, cheap - does it still work?)
- Sonnet (balanced - main use case)
- Opus (powerful - any edge cases?)

### 5. Gather Feedback

Use the skill in real scenarios:
- Does Claude invoke it appropriately?
- Are instructions clear enough?
- Does output format work well?
- Any missing error cases?

### 6. Iterate Continuously

Skills improve over time:
- Add caching when performance matters
- Refine error messages based on actual errors
- Add features based on real usage
- Simplify when complexity doesn't pay off

**Key principle**: Start simple, add complexity only when needed.

## Real-World Example

See `~/.claude/skills/fetching-github-prs-to-review/` for a production skill that:
- Fetches PRs from GitHub GraphQL API (~10KB response)
- Filters, groups, and formats in Python
- Returns ~2KB markdown summary
- ~80% token reduction
- Caches results with viewing history

This skill demonstrates all the patterns in this template.

## Checklist for New Skills

Before considering a skill complete:

- [ ] Follows naming convention (gerund + noun, e.g., `fetching-github-prs-to-review`)
- [ ] Description is clear, third-person, under 1024 characters
- [ ] SKILL.md describes when/how to use it (under 500 lines)
- [ ] Type hints on all functions
- [ ] Caching implemented (if applicable)
- [ ] Sensitive data sanitized
- [ ] Error handling with user-friendly messages
- [ ] No anti-patterns (Windows paths, too many options, assumed packages, etc.)
- [ ] Output formatted for readability
- [ ] Tested locally
- [ ] Token savings measured/documented
- [ ] Script is executable (`chmod +x`)

## Further Reading

- [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) - Token efficiency patterns
- [Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) - Official Claude docs
- Your existing skills for more examples (see `~/.claude/skills/`)
