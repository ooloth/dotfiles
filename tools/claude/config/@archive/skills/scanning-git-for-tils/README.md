# scanning-git-for-tils

Scans GitHub commit history for TIL-worthy commits and drafts blog posts in Notion.

## What It Does

1. **Scans commits** - Fetches your recent GitHub commits via `gh` CLI
2. **Filters candidates** - Skips dependabot, merges, bumps
3. **Checks assessed** - Queries Notion to avoid re-evaluating commits
4. **Returns formatted list** - Markdown summary for Claude to evaluate
5. **Drafts TILs** - Creates Notion pages with "Claude Draft" status

## Requirements

- Python 3.11+
- `uv` (for dependency management)
- `gh` CLI (authenticated to GitHub)
- `op` CLI (authenticated to 1Password for Notion token)
- Notion integration with access to:
  - Writing database (for drafts)
  - TIL Assessed Commits database (for tracking)

## Development Setup

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# No package installation needed - scripts use PEP 723 inline dependencies
# Dependencies auto-install when you run scripts with `uv run`
```

## Running Scripts

Scripts are self-contained with inline dependencies (PEP 723):

```bash
# Scan for TIL candidates (last 30 days)
uv run scan_git.py

# Scan custom time range
uv run scan_git.py 60

# Publish a TIL to Notion
uv run publish_til.py <commit-index>
```

## Running Tests

```bash
# Run all tests
uv run test_pure_functions.py

# Run with pytest for verbose output
uv run pytest test_pure_functions.py -v

# Run specific test class
uv run pytest test_pure_functions.py::TestFormatMarkdown -v
```

## Linting and Type Checking

```bash
# Run ruff (linting)
uv run --with ruff ruff check .

# Run mypy (type checking)
uv run --with mypy --with notion-client --with pydantic --with pytest \
  mypy --python-version 3.11 .
```

## Project Structure

```
scanning-git-for-tils/
├── git/
│   ├── commits.py     # GitHub API integration
│   ├── formatting.py  # Markdown formatting utilities
│   └── types.py       # Commit dataclass
├── notion/
│   ├── blocks.py      # Markdown → Notion blocks converter
│   ├── client.py      # Notion client factory
│   ├── commits.py     # Assessed commits tracking
│   ├── validation.py  # Pydantic models for API validation
│   └── writing.py     # Writing database operations
├── op/
│   └── secrets.py     # 1Password secret retrieval
├── scan_git.py        # Main script: scan for TIL candidates
├── publish_til.py     # Publishing script: create Notion drafts
├── test_pure_functions.py  # Test suite
├── pyproject.toml     # Tool configuration (ruff, mypy)
└── SKILL.md           # Claude skill definition
```

## Dependencies

Declared inline using [PEP 723](https://peps.python.org/pep-0723/) script metadata:

**Runtime:**

- `notion-client>=2.2.0` - Notion API v2025-09-03 support
- `pydantic>=2.0.0` - Runtime validation with v2 ConfigDict

**Development:**

- `pytest>=7.0.0` - Test framework
- `mypy>=1.0.0` - Static type checking
- `ruff>=0.1.0` - Linting and formatting

Dependencies auto-install when running scripts with `uv run`.

## Key Implementation Details

### Type Safety Approach

Uses Python with pragmatic type safety:

- Accept `Any` at SDK boundaries (GitHub, Notion APIs)
- Use Pydantic for runtime validation immediately after API calls
- Type hints throughout internal code
- Mypy configured for pragmatic checking (not strict mode)

### Notion API v2025-09-03

Uses latest Notion API patterns:

- `data_sources.query()` instead of `databases.query()`
- `collect_paginated_api()` helper for automatic pagination
- Pydantic validation on all API responses

### Error Handling

- 1Password failures raise `RuntimeError` with clear messages
- Notion/GitHub API errors caught and return empty sets gracefully
- Test suite validates all error paths

## Configuration

Tool configuration in `pyproject.toml`:

**Ruff:**

- Line length: 100
- Target: Python 3.11
- Import sorting (I) and pyupgrade (UP) enabled

**Mypy:**

- Python 3.11 syntax
- Non-strict mode (pragmatic for SDK code)
- Excludes .venv/ and build directories
