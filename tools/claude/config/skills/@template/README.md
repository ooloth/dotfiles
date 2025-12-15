# Skill Template

This template demonstrates best practices for creating skills that follow the MCP code execution pattern described in [Code Execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp).

## When to Create a Skill

Create a skill (instead of a command or agent) when:

1. **Token-heavy operations**: The task involves fetching/processing large amounts of data
2. **Deterministic logic**: The processing doesn't require Claude's reasoning
3. **Filtering benefits**: You can filter/summarize data in code before returning to Claude
4. **Caching opportunities**: Results can be cached to avoid redundant operations
5. **Type safety matters**: Structured data with typed interfaces improves reliability

## Implementation Approach: Python + uv

Skills are implemented in **Python with uv** using the single-file script pattern ([PEP 723](https://peps.python.org/pep-0723/)):

### Why Python + uv?

✅ **Self-contained scripts** - Dependencies declared inline, auto-install with `uv run`
✅ **Rich ecosystem** - Excellent SDKs for most external services (GitHub, Notion, Slack, etc.)
✅ **Pragmatic typing** - Good-enough type safety without fighting the type system
✅ **Fast iteration** - No build step, quick prototyping
✅ **Familiar tooling** - Standard Python ecosystem (mypy, ruff, pytest)

### Key Principles

1. **Use SDKs over raw HTTP** - Prefer official/well-maintained SDKs for external data sources (GitHub, Notion, Jira, etc.) rather than building your own API clients
2. **Single-file scripts** - Use PEP 723 inline dependencies, not pyproject.toml package definitions
3. **Pragmatic type safety** - Type hints everywhere, Pydantic at API boundaries, mypy in non-strict mode

## Type Safety Patterns

### Pydantic for Parsing Outputs (Not Inputs)

Use Pydantic to **validate API responses** (outputs from external APIs), not to validate your own function inputs:

```python
from pydantic import BaseModel, ConfigDict

class NotionPageResponse(BaseModel):
    """Validated Notion API response."""

    model_config = ConfigDict(extra="ignore")  # Pydantic v2 pattern

    url: str
    id: str

def create_page(notion, title: str) -> str:
    """Create page and return URL."""
    # Call external API
    response = notion.pages.create(...)

    # ✅ Validate immediately after API call
    page = NotionPageResponse.model_validate(response)

    # ✅ Extract and return values immediately
    return page.url  # Don't pass Pydantic models around
```

**Pattern:**

1. External API returns data (untyped `dict`)
2. Validate with Pydantic **immediately**
3. Extract needed values (primitives or dataclasses)
4. Use extracted values in rest of code

**Why:** Pydantic provides runtime validation at the boundary where types are uncertain (external APIs). Once validated, use native Python types.

### Dataclasses for Internal Data

Use dataclasses for internal data structures:

```python
from dataclasses import dataclass

@dataclass
class Commit:
    """A git commit with metadata."""

    hash: str
    message: str
    repo: str
    date: str
    files: list[str]

def process_commits(commits: list[Commit]) -> str:
    """Process commits - type-safe throughout."""
    # Work with well-typed data, no runtime validation needed
    return format_markdown(commits)
```

**Why:** Dataclasses are lightweight, well-integrated with mypy, and perfect for internal data that's already validated.

### TypeGuard for Narrowing Types

When you need to narrow types beyond simple `isinstance` checks:

```python
from typing import TypeGuard

def is_valid_commit(data: dict) -> TypeGuard[dict]:
    """Type guard to narrow dict to valid commit structure."""
    return (
        isinstance(data.get("hash"), str) and
        isinstance(data.get("message"), str) and
        isinstance(data.get("repo"), str)
    )

def process_data(items: list[dict]) -> list[Commit]:
    """Process raw data with type narrowing."""
    commits = []
    for item in items:
        if is_valid_commit(item):
            # mypy knows item has required fields
            commits.append(Commit(
                hash=item["hash"],
                message=item["message"],
                repo=item["repo"],
                date=item.get("date", ""),
                files=item.get("files", [])
            ))
    return commits
```

**When to use:** Complex validation logic that you want mypy to understand.

### Pydantic → Dataclass Conversion

For complex APIs, validate with Pydantic then convert to dataclass:

```python
from pydantic import BaseModel
from dataclasses import dataclass

class NotionPageValidation(BaseModel):
    """Pydantic model for validation only."""
    url: str
    id: str
    properties: dict

@dataclass
class NotionPage:
    """Dataclass for internal use."""
    url: str
    id: str
    title: str

def fetch_page(page_id: str) -> NotionPage:
    """Fetch and validate page from API."""
    response = notion.pages.retrieve(page_id)

    # Validate with Pydantic
    validated = NotionPageValidation.model_validate(response)

    # Extract to dataclass
    title = validated.properties.get("Title", {}).get("title", [{}])[0].get("plain_text", "")
    return NotionPage(
        url=validated.url,
        id=validated.id,
        title=title
    )
```

**When to use:** When you need both runtime validation (Pydantic) and clean internal types (dataclass).

## Mitigating Non-Strict Mypy

Since we use `strict = false` for pragmatic SDK integration, compensate with these patterns:

### 1. Type Hints Everywhere

```python
# ✅ Always include type hints
def get_commits(days: int, username: str) -> list[Commit]:
    """Fetch commits from GitHub API."""
    # ...

# ✅ Modern syntax (list[T], not List[T])
from __future__ import annotations

def process(items: list[str]) -> dict[str, int]:
    # ...

# ✅ Union types with |
def find_user(username: str) -> User | None:
    # ...

# ❌ Don't rely on inference
def process(items):  # Type unknown!
    # ...
```

### 2. Explicit Return Types

```python
# ✅ Always declare return type
def parse_date(date_str: str) -> str:
    if not date_str:
        return "unknown"
    # ...
    return formatted

# ❌ Don't let mypy infer
def parse_date(date_str: str):  # Return type inferred (fragile)
    # ...
```

### 3. Handle None Explicitly

```python
# ✅ Check for None before using
def get_title(page: dict) -> str:
    title_prop = page.get("properties", {}).get("Title")
    if not title_prop:
        return ""

    title_content = title_prop.get("title", [])
    if not title_content:
        return ""

    return title_content[0].get("plain_text", "")

# ❌ Don't assume values exist
def get_title(page: dict) -> str:
    return page["properties"]["Title"]["title"][0]["plain_text"]  # Can crash!
```

### 4. Accept Any at SDK Boundaries Only

```python
from typing import Any

# ✅ Accept Any from SDK, validate immediately
def create_page(notion, title: str) -> str:
    response: Any = notion.pages.create(...)  # SDK returns Any
    page = NotionPageResponse.model_validate(response)  # Validate
    return page.url  # Type-safe from here

# ✅ Internal functions are fully typed
def format_markdown(commits: list[Commit]) -> str:
    # No Any types here
    # ...
```

### 5. Small, Well-Typed Helper Functions

```python
# ✅ Break complex logic into small, typed pieces
def _map_language_alias(language: str) -> str:
    """Map language names to Notion's expected values."""
    lang_map = {
        "js": "javascript",
        "ts": "typescript",
        "py": "python",
    }
    return lang_map.get(language, language) or "plain text"

def _create_code_block(lines: list[str], start_index: int) -> tuple[dict, int]:
    """Create code block from markdown.

    Returns: (block dict, next line index)
    """
    language = _map_language_alias(lines[start_index][3:].strip())
    # ...
    return block, next_index
```

**Why:** Small functions are easier to type correctly and verify.

## Testing Patterns

### Comprehensive Unit Tests for Pure Functions

Test all pure functions (no I/O, deterministic output):

```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest", "notion-client", "pydantic"]
# ///

from git.formatting import format_markdown, should_skip_commit
from git.types import Commit

class TestFormatMarkdown:
    """Test markdown formatting."""

    def test_formats_empty_list(self):
        result = format_markdown([], 30, 0, 0)
        assert "No commits found" in result

    def test_formats_single_commit(self):
        commit = Commit(
            hash="abc1234",
            message="feat: add feature",
            repo="owner/repo",
            date="2 days ago",
            files=["main.py"]
        )
        result = format_markdown([commit], 30, 1, 1)

        assert "[owner/repo] feat: add feature" in result
        assert "Hash: abc1234" in result

if __name__ == "__main__":
    import pytest
    import sys
    sys.exit(pytest.main([__file__, "-v"]))
```

### Test Helpers for Readability

Create helpers to make tests clear and maintainable:

```python
def make_notion_page(commit_hash: str) -> dict:
    """Helper: create mock Notion page with commit hash."""
    return {
        "properties": {
            "Commit Hash": {"title": [{"plain_text": commit_hash}]}
        }
    }

def make_notion_response(hashes: list[str]) -> dict:
    """Helper: create mock Notion SDK response."""
    return {
        "results": [make_notion_page(h) for h in hashes],
        "has_more": False,
    }

class TestGetAssessedCommits:
    def test_returns_commit_hashes(self):
        with patch("notion_client.Client") as MockClient:
            mock_client = MockClient.return_value
            mock_client.data_sources.query.return_value = make_notion_response(
                ["abc123", "def456"]
            )

            result = get_assessed_commits()
            assert result == {"abc123", "def456"}
```

### Test Edge Cases

Always test edge cases:

```python
class TestFormatRelativeDate:
    def test_handles_invalid_date(self):
        result = format_relative_date("not-a-date")
        assert result == "unknown"

    def test_handles_empty_string(self):
        result = format_relative_date("")
        assert result == "unknown"

class TestShouldSkipCommit:
    def test_skips_dependabot(self):
        commit = Commit(hash="abc", message="Bump dependency from 1.0 to 2.0", ...)
        assert should_skip_commit(commit) is True

    def test_keeps_normal_commits(self):
        commit = Commit(hash="abc", message="fix: handle null values", ...)
        assert should_skip_commit(commit) is False
```

### Mock External Dependencies

Mock all external I/O (APIs, CLIs, file system):

```python
from unittest.mock import patch

class TestGetAssessedCommits:
    def test_returns_empty_set_when_no_token(self):
        with patch("notion.commits.get_op_secret", side_effect=RuntimeError("Failed")):
            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_handles_api_error_gracefully(self):
        with (
            patch("notion.commits.get_op_secret", return_value="fake-token"),
            patch("notion_client.Client") as MockClient,
        ):
            MockClient.side_effect = Exception("Connection error")

            result = get_assessed_commits_from_notion()
            assert result == set()
```

### Class-Based Test Organization

Group related tests in classes:

```python
class TestFormatMarkdown:
    """Test markdown formatting."""
    # All markdown tests here

class TestShouldSkipCommit:
    """Test commit filtering."""
    # All filtering tests here

class TestExtractPageId:
    """Test Notion URL parsing."""
    # All URL tests here
```

**Why:** Clear organization, easy to run subsets (`pytest test_file.py::TestClass`)

### Descriptive Test Names

Use names that describe what's being tested:

```python
# ✅ Clear what's being tested
def test_formats_commit_with_long_body(self):
def test_handles_pagination(self):
def test_returns_empty_set_when_no_token(self):
def test_skips_pages_without_commit_hash(self):

# ❌ Vague names
def test_format(self):
def test_pagination(self):
def test_error(self):
```

## Error Handling Patterns

### Raise Clear Exceptions at Boundaries

```python
def get_op_secret(path: str) -> str:
    """Fetch secret from 1Password.

    Raises:
        RuntimeError: If 1Password CLI fails with error details.
    """
    result = subprocess.run(["op", "read", path], capture_output=True, text=True)

    if result.returncode != 0:
        # ✅ Raise with clear message including details
        raise RuntimeError(
            f"Failed to retrieve secret from 1Password: {result.stderr.strip()}"
        )

    return result.stdout.strip()
```

### Handle Errors Gracefully at Call Sites

```python
def get_assessed_commits_from_notion() -> set[str]:
    """Fetch assessed commits from Notion.

    Returns empty set on any error for graceful degradation.
    """
    try:
        token = get_op_secret(OP_NOTION_TOKEN_PATH)  # Can raise RuntimeError
        notion = Client(auth=token)
    except Exception:
        # ✅ Graceful degradation - return empty set
        return set()

    try:
        pages = notion.data_sources.query(...)
        return {extract_hash(p) for p in pages}
    except Exception:
        # ✅ API errors also degrade gracefully
        return set()
```

### Document Error Behavior

```python
def create_page(notion, title: str) -> str:
    """Create page in Notion.

    Returns:
        URL of created page.

    Raises:
        Exception: If page creation fails with error details.
    """
    response = notion.pages.create(...)
    page = NotionPageResponse.model_validate(response)
    return page.url
```

**Pattern:** Raise at boundaries with details, handle gracefully at call sites, document behavior.

## Authentication Patterns

### macOS Keychain for API Tokens

For skills that need API tokens, use this secure caching pattern with macOS Keychain:

```python
import os
import subprocess
import sys

# Keychain configuration
KEYCHAIN_SERVICE = "claude-your-service-api-token"
KEYCHAIN_ACCOUNT = os.environ.get("USER", "default")

def get_token_from_keychain() -> str | None:
    """Retrieve token from macOS Keychain.

    Returns None if not found. Keychain is OS-encrypted and unlocked at login.
    """
    result = subprocess.run(
        ["security", "find-generic-password",
         "-a", KEYCHAIN_ACCOUNT,
         "-s", KEYCHAIN_SERVICE,
         "-w"],  # -w outputs password only
        capture_output=True,
        text=True,
        timeout=5,
    )

    if result.returncode == 0:
        return result.stdout.strip()
    return None

def store_token_in_keychain(token: str) -> None:
    """Store token in macOS Keychain (OS-encrypted).

    Raises:
        RuntimeError: If keychain storage fails.
    """
    # Delete existing entry first (idempotent)
    subprocess.run(
        ["security", "delete-generic-password",
         "-a", KEYCHAIN_ACCOUNT,
         "-s", KEYCHAIN_SERVICE],
        capture_output=True,
        timeout=5,
    )

    # Add new entry
    result = subprocess.run(
        ["security", "add-generic-password",
         "-a", KEYCHAIN_ACCOUNT,
         "-s", KEYCHAIN_SERVICE,
         "-w", token],  # -w reads password from argument
        capture_output=True,
        text=True,
        timeout=5,
    )

    if result.returncode != 0:
        raise RuntimeError(f"Failed to store token in keychain: {result.stderr}")

def get_token_from_1password() -> str:
    """Fetch token from 1Password CLI.

    Raises:
        RuntimeError: If 1Password CLI fails.
    """
    result = subprocess.run(
        ["op", "read", "op://Scripts/Your-Service/api-token"],
        capture_output=True,
        text=True,
        timeout=30,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"Failed to retrieve token from 1Password: {result.stderr.strip()}"
        )

    return result.stdout.strip()

def get_api_token() -> str:
    """Get API token with three-tier fallback.

    Priority:
    1. Environment variable (if user sets it manually)
    2. macOS Keychain (encrypted, persistent across sessions)
    3. 1Password CLI (fetches and caches in keychain for next time)

    Returns:
        API token string.

    Raises:
        RuntimeError: If all methods fail.
    """
    # Priority 1: User-set environment variable
    token = os.environ.get("YOUR_SERVICE_TOKEN")
    if token:
        return token

    # Priority 2: macOS Keychain (instant, no prompts)
    token = get_token_from_keychain()
    if token:
        return token

    # Priority 3: 1Password CLI (one prompt, then cache)
    try:
        token = get_token_from_1password()

        # Cache for next time
        try:
            store_token_in_keychain(token)
        except Exception as e:
            # Non-fatal: token still works, just won't be cached
            print(
                f"Warning: Could not cache token in keychain: {e}",
                file=sys.stderr
            )

        return token

    except Exception as e:
        raise RuntimeError(f"Failed to retrieve API token: {e}")
```

**Usage in your skill:**

```python
def main() -> None:
    try:
        token = get_api_token()
        client = YourServiceClient(auth=token)
        # ... use client
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
```

**User experience:**

First invocation:

1. Prompts for 1Password fingerprint (once)
2. Stores token in macOS Keychain (OS-encrypted)
3. Executes skill

Subsequent invocations:

1. Retrieves from keychain (instant, no prompts)
2. Executes skill

**Why this pattern:**

✅ **Secure**: Tokens encrypted by macOS, never in plaintext files
✅ **Persistent**: Survives session restarts, no repeated prompts
✅ **Fast**: Keychain retrieval is instant after first use
✅ **User-friendly**: One prompt per machine, then seamless
✅ **Override-able**: Users can set env var to skip keychain entirely

## Skills vs Agents vs Commands

| Approach    | Use When                                          | Example                                               |
| ----------- | ------------------------------------------------- | ----------------------------------------------------- |
| **Skill**   | Heavy data processing, filtering, caching         | `fetching-github-prs-to-review`, `analyzing-codebase` |
| **Agent**   | Complex exploration requiring multiple tool calls | `Explore`, `Plan`, `atomic-committer`                 |
| **Command** | Simple prompts that need Claude's reasoning       | `/plan`, `/fix-bug`                                   |

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

### 3. Choose Your Language

**For Python skills:**

- Use PEP 723 inline script metadata for dependencies
- Include type hints for reliability
- See `example_skill.py` for the template

**For TypeScript/Bun skills:**

- Use inline version specifiers: `import { z } from "zod@^3.22.4"`
- Leverage Zod for validation + types (single system)
- See `scanning-git-for-tils` skill for real-world example

### 4. Implement Your Logic

**In `example_skill.py` (Python):**

1. **Configuration** (lines 18-26): Update cache file names, TTLs, etc.
2. **Type Definitions** (lines 30-48): Define your data structures
3. **fetch_raw_data()** (lines 90-106): Implement your data source
4. **filter_and_process()** (lines 129-171): Filter and transform data
5. **format_markdown()** (lines 177-203): Format output for display

**In TypeScript/Bun:**

- Define Zod schemas for validation AND types
- Use `Bun.spawn()` for process execution
- Return JSON to stdout for Claude to parse

### 5. Test Your Skill

```bash
# Test locally first
python3 ~/.claude/skills/your-skill-name/your_script.py

# Verify caching works
python3 ~/.claude/skills/your-skill-name/your_script.py  # Should use cache
```

### 6. Document Token Savings

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
