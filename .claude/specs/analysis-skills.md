# Analysis Skills - Tool Output Processing

## Goal

Create skills that process development tool output (type checkers, test runners, linters) into focused summaries, enabling 80-98% token savings and proactive analysis.

## Key Insight

**Skills that process tool output are more valuable than skills that guide workflows.**

**Correct pattern:**
- Skills **process data** (run tools, filter output, return summaries)
- Commands **guide reasoning** (use processed data to make decisions)

**Example:**
```
✅ Create `analyzing-type-errors` skill that processes mypy output
✅ Keep `/fix-types` command that uses the processed data for reasoning
❌ Don't convert `/fix-types` command into a workflow-guiding skill
```

**Why:** Commands already guide workflows well using Claude's reasoning. The opportunity is processing verbose tool output into focused summaries.

## The Pattern

### Analysis Skills Follow This Structure

1. **Input**: File paths, project directory, or auto-detect
2. **Process**:
   - Run development tool (mypy, pytest, ruff, coverage, etc.)
   - Parse verbose output
   - Filter noise (e.g., passing tests, irrelevant warnings)
   - Group by meaningful categories (file, error type, severity)
   - Cache results (keyed by file hashes or test IDs)
3. **Output**: Focused markdown summary with:
   - Grouped issues
   - File:line references
   - Severity/priority indicators
   - Auto-fixable flags where applicable
   - Token count: 10-20% of raw tool output

### Why This Works

**Token efficiency example:**
```
Raw mypy output:    3,500 tokens (includes file paths, context, formatting)
Skill summary:        400 tokens (grouped errors, file:line, descriptions)
Savings:            ~89%
```

**Proactive invocation:**
- Claude sees type errors in code review → invokes `analyzing-type-errors`
- Claude encounters test failures → invokes `analyzing-test-failures`
- User asks to improve code quality → invokes `analyzing-code-quality`

**Caching value:**
- Type errors: Cache by file hash (avoid re-running on unchanged files)
- Test failures: Cache by commit hash (iterate on fixes without re-running)
- Lint results: Cache by file hash (fast iterative fixes)

## Identified Opportunities

### Priority 1: `analyzing-type-errors` ⭐⭐⭐

**What it does:**
Runs type checker (mypy for Python, tsc for TypeScript), parses output, returns structured errors grouped by file and error type.

**Why it's highest priority:**
- Type checker output is extremely verbose (paths, context, hints)
- Errors are highly structured (file:line:column, error code, message)
- Clear grouping opportunities (by file, by error type, by auto-fixability)
- High token savings (85-90%)
- Proactive use case is obvious (Claude sees type errors)

**Input:**
```python
# Option 1: Specific files
python3 ~/.claude/skills/analyzing-type-errors/analyze.py src/module.py

# Option 2: Whole project (auto-detect mypy/tsc/pyright)
python3 ~/.claude/skills/analyzing-type-errors/analyze.py

# Option 3: JSON output for programmatic use
python3 ~/.claude/skills/analyzing-type-errors/analyze.py --format json
```

**Output example:**
```markdown
# Type Errors Analysis

**Summary**: 12 errors across 4 files (mypy 1.8.0)

## By Error Type

### Undefined name (5 errors) - CRITICAL
- `src/utils.py:42`: Name 'random_seed' is not defined [F821]
- `src/utils.py:44`: Name 'random_seed' is not defined [F821]
- `src/config.py:15`: Name 'Optional' is not defined [F821]
  - **Fix**: Add `from typing import Optional`
- (2 more...)

### Missing type annotations (4 errors) - MEDIUM
- `src/service.py:23`: Function missing return type annotation
- `src/service.py:67`: Function missing return type annotation
  - **Auto-fixable**: Can infer from return statements
- (2 more...)

### Incompatible types (3 errors) - HIGH
- `src/models.py:89`: Argument has incompatible type "str"; expected "int"
- `src/models.py:102`: Incompatible return type: expected "Dict[str, Any]", got "List[Any]"
- (1 more...)

## By File

- `src/utils.py`: 3 errors (2 critical, 1 medium)
- `src/config.py`: 4 errors (1 critical, 3 medium)
- `src/models.py`: 3 errors (all high priority)
- `src/service.py`: 2 errors (both medium, auto-fixable)

## Recommended Fix Order

1. **CRITICAL**: Fix 3 undefined names in src/utils.py (runtime errors)
2. **HIGH**: Fix type incompatibilities in src/models.py (logic errors)
3. **MEDIUM**: Add type annotations (4 auto-fixable via pyright --createstub)
```

**Caching strategy:**
```python
# Cache key: hash of (file_contents + mypy_version)
# Invalidate: When file changes or mypy updates
# TTL: No expiration (cache until file changes)
# Storage: ~/.claude/.cache/analyzing-type-errors/
#   {file_hash}.json containing parsed errors
```

**Integration with existing workflows:**
- `/fix-types` command: "First, run the analyzing-type-errors skill to get structured output"
- Proactive: When Claude sees type errors in code, suggest running skill
- Review: Before `/review-code`, optionally analyze type coverage

**Implementation notes:**
- Detect type checker: Check for mypy.ini/pyproject.toml (mypy), tsconfig.json (tsc)
- Parse output: Use regex to extract file:line:column, error code, message
- Error classification:
  - CRITICAL: Undefined names, import errors (runtime failures)
  - HIGH: Type incompatibilities, missing required args (logic errors)
  - MEDIUM: Missing annotations, unused imports (quality issues)
  - LOW: Style issues (can be ignored)
- Auto-fixable detection:
  - Missing imports: Can suggest exact import statement
  - Missing type annotations: If tool supports --createstub
  - Type: ignore comments: Always an option (document why)

### Priority 2: `analyzing-test-failures` ⭐⭐⭐

**What it does:**
Runs test suite (pytest, jest, etc.), parses output, returns only failures with assertions, stack traces, and grouping.

**Why it's high priority:**
- Test output includes passes (noise) - skill filters to only failures
- Stack traces are verbose - skill extracts relevant frames
- Clear grouping: by test file, by assertion type, by error type
- High token savings (90%+)
- Proactive: Claude can run when tests fail in conversation

**Input:**
```bash
# Run all tests
python3 ~/.claude/skills/analyzing-test-failures/analyze.py

# Specific test file or pattern
python3 ~/.claude/skills/analyzing-test-failures/analyze.py tests/test_auth.py

# With coverage data (if available)
python3 ~/.claude/skills/analyzing-test-failures/analyze.py --with-coverage
```

**Output example:**
```markdown
# Test Failures Analysis

**Summary**: 7 failures, 145 passed (pytest 8.0.0) - Run time: 12.3s

## Failures by Type

### AssertionError (4 failures)

**tests/test_auth.py::test_login_invalid_credentials**
```python
assert response.status_code == 401
AssertionError: assert 500 == 401
```
- Expected: 401 Unauthorized
- Got: 500 Internal Server Error
- **Likely cause**: Uncaught exception in auth handler

**tests/test_auth.py::test_password_reset**
```python
assert email_sent is True
AssertionError: assert False is True
```
- Mock email service not properly configured in test
- Stack trace: tests/test_auth.py:67 → src/auth.py:143 → src/email.py:22
- **Likely cause**: Missing mock setup

(2 more...)

### AttributeError (2 failures)

**tests/test_models.py::test_user_profile**
```
AttributeError: 'NoneType' object has no attribute 'username'
```
- Stack trace: tests/test_models.py:34 → src/models.py:89
- **Likely cause**: Database fixture not creating user properly

(1 more...)

### ImportError (1 failure)

**tests/test_utils.py::test_date_formatting**
```
ImportError: cannot import name 'format_date' from 'src.utils'
```
- **Likely cause**: Function was renamed or removed

## By Test File

- `tests/test_auth.py`: 4 failures (2 assertion, 2 setup issues)
- `tests/test_models.py`: 2 failures (1 attribute error, 1 fixture issue)
- `tests/test_utils.py`: 1 failure (import error)

## Recommended Fix Order

1. **Fix import error** in test_utils.py (blocks test from running)
2. **Fix fixture issues** in test_models.py and test_auth.py (setup problems)
3. **Fix assertion failures** in test_auth.py (actual logic issues)

## Additional Context

- **Flaky tests**: None detected (all failures consistent across 3 runs)
- **New failures**: 2 tests (test_password_reset, test_user_profile) passed on main branch
- **Coverage**: 87% (down from 89% on main due to new uncovered error paths)
```

**Caching strategy:**
```python
# Cache key: commit_hash + test_path
# Invalidate: On new commits or when test files change
# TTL: Until next commit (for iterative fixing)
# Storage: ~/.claude/.cache/analyzing-test-failures/
#   {commit_hash}_{test_path_hash}.json
```

**Integration:**
- `/fix-tests` command uses this for systematic failure analysis
- Proactive: When tests fail during development
- CI integration: Can parse CI test output from `inspecting-codefresh-failures`

**Implementation notes:**
- Detect test framework: pytest (pytest.ini), jest (jest.config.js), unittest (standard library)
- Parse output formats:
  - pytest: Use `--tb=short` for concise traces
  - jest: JSON reporter for structured data
  - unittest: Parse verbose output
- Group failures:
  - By exception type (AssertionError, AttributeError, etc.)
  - By test file
  - By setup/teardown vs test body failures
- Extract relevant stack frames:
  - Filter out framework internals
  - Show test file line + source file line
  - Include local variables if available (pytest -vv)
- Detect patterns:
  - Flaky tests (failures that don't reproduce)
  - New failures (compare with previous runs)
  - Fixture issues (failures in setup/teardown)

### Priority 3: `analyzing-code-quality` ⭐⭐

**What it does:**
Runs configured linters (ruff, eslint, flake8, etc.), parses output, groups issues by type and severity.

**Why it's valuable:**
- Linter output is highly repetitive (same violation across many files)
- Can prioritize critical vs cosmetic issues
- Can identify auto-fixable issues
- Medium token savings (70-80%) - less than type errors because already somewhat structured
- Useful for code reviews and cleanup

**Input:**
```bash
# Run all configured linters
python3 ~/.claude/skills/analyzing-code-quality/analyze.py

# Specific files
python3 ~/.claude/skills/analyzing-code-quality/analyze.py src/module.py

# Specific linter
python3 ~/.claude/skills/analyzing-code-quality/analyze.py --linter ruff
```

**Output example:**
```markdown
# Code Quality Analysis

**Summary**: 23 issues across 8 files (ruff 0.1.0)

## By Severity

### ERROR (3 issues) - Must fix
- **F821**: Undefined name `config` (2 occurrences)
  - src/service.py:45
  - src/handlers.py:23
  - **Fix**: Import or define `config`
- **E999**: SyntaxError: invalid syntax (1 occurrence)
  - src/legacy.py:156
  - **Fix**: Likely missing closing bracket

### WARNING (12 issues) - Should fix
- **W503**: Line break before binary operator (8 occurrences)
  - **Auto-fixable**: `ruff --fix`
- **F401**: Unused import (4 occurrences)
  - **Auto-fixable**: `ruff --fix`

### INFO (8 issues) - Optional improvements
- **E501**: Line too long (>120 chars) (5 occurrences)
  - Not auto-fixable (requires refactoring)
- **N806**: Variable in function should be lowercase (3 occurrences)
  - **Auto-fixable**: Rename variables

## By Category

### Critical Issues (3)
All are blocking errors that prevent code from running.

### Auto-fixable (12)
Can be fixed automatically with `ruff --fix`.

### Manual Fixes Required (8)
Require code refactoring or decisions.

## By File

- `src/service.py`: 6 issues (1 error, 3 warning, 2 info)
- `src/handlers.py`: 5 issues (1 error, 2 warning, 2 info)
- `src/legacy.py`: 4 issues (1 error, 3 warning)
- (5 more files...)

## Recommended Action Plan

1. **Fix 3 ERROR-level issues** (blocking problems)
2. **Run `ruff --fix`** to auto-fix 12 issues
3. **Review remaining 8 INFO issues** (decide which to fix)
```

**Caching strategy:**
```python
# Cache key: hash(file_contents + linter_version + linter_config)
# Invalidate: When file or config changes
# TTL: No expiration (until file changes)
# Storage: ~/.claude/.cache/analyzing-code-quality/
#   {file_hash}_{linter}.json
```

**Integration:**
- `/review-code` command can optionally run this first
- `/fix-code` uses grouped output to prioritize fixes
- Proactive: Before creating PRs

**Implementation notes:**
- Detect linters: Check for config files (ruff.toml, .eslintrc, etc.)
- Support multiple linters per language:
  - Python: ruff, flake8, pylint, black (formatting)
  - JavaScript/TypeScript: eslint, prettier
  - Go: golangci-lint
  - Rust: clippy
- Severity mapping:
  - ERROR: Syntax errors, undefined names, runtime failures
  - WARNING: Code smells, likely bugs, deprecated APIs
  - INFO: Style issues, complexity warnings, documentation
- Auto-fix detection:
  - Check if linter supports `--fix` flag
  - Parse output for "fixable" annotations
  - Group fixable vs manual-fix-needed
- Aggregate across linters:
  - De-duplicate overlapping issues
  - Normalize severity levels across tools
  - Present unified view

### Future Consideration: `analyzing-test-coverage`

**What it does:**
Runs coverage tool, identifies uncovered code, ranks gaps by importance.

**Why lower priority:**
- Less frequently needed (not part of normal workflow)
- Coverage reports are structured but very large
- Ranking logic is complex (usage frequency, complexity, criticality)
- Mainly for targeted coverage improvement efforts

**Defer until:** The first three analysis skills prove their value.

## Design Principles for Analysis Skills

### 1. Tool Detection Over Configuration

**Do this:**
```python
def detect_type_checker() -> str:
    """Auto-detect which type checker is configured."""
    if Path("mypy.ini").exists() or "mypy" in pyproject_toml:
        return "mypy"
    elif Path("pyrightconfig.json").exists():
        return "pyright"
    elif Path("tsconfig.json").exists():
        return "tsc"
    else:
        raise ToolNotFoundError("No type checker configured")
```

**Not this:**
```python
# Don't require user to specify which tool
analyze.py --tool mypy  # Too much friction
```

**Why:** Follows "don't assume package installations" anti-pattern from template, but extends it to auto-detect what IS installed.

### 2. Cache Processed Data, Not Raw Output

**Do this:**
```python
# Cache the parsed, grouped, structured data
cache = {
    "errors_by_type": {"F821": [...], "E501": [...]},
    "errors_by_file": {"src/utils.py": [...], ...},
    "summary": {"total": 12, "critical": 3, ...}
}
save_cache(file_hash, cache)
```

**Not this:**
```python
# Don't cache raw tool output
raw_output = subprocess.run(["mypy", "."]).stdout
save_cache(file_hash, raw_output)  # Still needs parsing
```

**Why:** Follows MCP pattern - cache the processed result, not raw data.

### 3. Provide Both Human and Machine Formats

**Do this:**
```python
def main():
    result = analyze_types()

    if "--format" in sys.argv and sys.argv[sys.argv.index("--format") + 1] == "json":
        print(format_json(result))
    else:
        print(format_markdown(result))
```

**Why:**
- Markdown for Claude/human reading (default)
- JSON for programmatic use (other tools, scripts, dashboards)

### 4. Group for Actionability

**Do this:**
```markdown
## By Error Type
### Undefined name (5 errors) - CRITICAL
...

## By File
- src/utils.py: 3 errors

## Recommended Fix Order
1. Fix critical undefined names
2. Fix type incompatibilities
```

**Not this:**
```markdown
## All Errors
- src/utils.py:42 - undefined name
- src/config.py:15 - undefined name
- src/models.py:89 - incompatible type
- src/utils.py:44 - undefined name
(unordered, ungrouped wall of errors)
```

**Why:** Groups enable Claude to reason systematically about fix strategy.

### 5. Include Metadata for Context

**Do this:**
```markdown
**Summary**: 12 errors across 4 files (mypy 1.8.0)
**Analyzed**: 45 files, 3,200 lines
**Runtime**: 2.3s
**Cache**: Hit (src/config.py, src/models.py), Miss (src/utils.py, src/service.py)
```

**Why:**
- Tool version helps debug parser issues
- Runtime informs whether to cache
- Cache hit/miss explains freshness
- File/line counts provide scale

### 6. Explain Auto-fixability

**Do this:**
```markdown
### Missing type annotations (4 errors) - MEDIUM
- src/service.py:23: Function missing return type annotation
  - **Auto-fixable**: Can infer from return statements
  - **How**: Run `pyright --createstub src/service.py`
```

**Not this:**
```markdown
- src/service.py:23: Function missing return type annotation
(no guidance on how to fix)
```

**Why:** Empowers Claude to suggest specific fix commands.

## Implementation Guidance

### Follow the Template

**Structure and patterns:** See `tools/claude/config/skills/@template/` for:
- File structure (SKILL.md, script.py, README.md)
- Type hints and error handling patterns
- Caching implementation (cache processed data, not raw output)
- Output formatting (markdown and JSON)
- Anti-patterns to avoid

### Specific to Analysis Skills

**Script structure:**
```python
# 1. Tool detection (auto-detect from project config)
def detect_tool() -> str:
    """Find mypy/pytest/ruff from config files."""

# 2. Run and capture output
def run_tool(tool: str, files: List[str]) -> str:
    """Execute tool, return raw output."""

# 3. Parse into structured format
def parse_output(tool: str, output: str) -> List[Issue]:
    """Convert verbose output to structured data."""

# 4. Group for actionability
def group_issues(issues: List[Issue]) -> AnalysisResult:
    """Group by type, file, severity, etc."""

# 5. Cache by content hash
cache_key = hash(file_contents + tool_version)

# 6. Format summary (10-20% of raw output size)
def format_markdown(result: AnalysisResult) -> str:
    """Return focused summary with file:line references."""
```

**Key differences from template:**
- Tool detection logic (not hardcoded commands)
- Output parsing (tool-specific regex/JSON parsing)
- Grouping logic (by error type, severity, file, etc.)
- Cache invalidation (by file hash, not time-based TTL)

## Success Criteria

### For Each Analysis Skill

- [ ] Auto-detects tool from project configuration
- [ ] Runs tool and captures output
- [ ] Parses output into structured format
- [ ] Groups errors/failures/issues meaningfully
- [ ] Classifies severity/priority
- [ ] Identifies auto-fixable items
- [ ] Caches processed results (not raw output)
- [ ] Returns focused markdown summary (10-20% of raw size)
- [ ] Supports JSON output for programmatic use
- [ ] Includes metadata (tool version, runtime, cache status)
- [ ] Handles errors gracefully (tool not found, no config, etc.)
- [ ] Follows template patterns (type hints, error handling, caching)

### For Integration

- [ ] Relevant commands reference the analysis skill
- [ ] Claude can invoke proactively when appropriate
- [ ] Token savings measured and documented (goal: 80%+)
- [ ] Caching provides measurable performance benefit
- [ ] Skills compose well (one skill's output feeds another command)

## Implementation Order

### Phase 1: `analyzing-type-errors` (Foundational)

**Why first:**
- Clearest use case and highest token savings
- Type checker output is highly structured (easy to parse)
- Existing `/fix-types` command provides clear integration point
- Success will validate the pattern for other analysis skills

**Deliverables:**
- Skill implementation with mypy support
- Integration with `/fix-types` command
- Documentation and examples
- Token savings measurement

**Validation:**
- Run on a Python project with type errors
- Measure token count: raw mypy output vs skill summary
- Verify cache hit/miss behavior
- Confirm `/fix-types` workflow improvement

### Phase 2: `analyzing-test-failures`

**Why second:**
- Natural follow-on (similar pattern, different domain)
- Test output is even more verbose than type errors (higher savings)
- Clear integration with `/fix-tests` command
- Validates pattern works across different tool types

**Deliverables:**
- Skill implementation with pytest support
- Integration with `/fix-tests` command
- Documentation and examples

### Phase 3: `analyzing-code-quality`

**Why third:**
- Most complex (multiple linters, severity mapping, aggregation)
- Benefit from lessons learned in phases 1 and 2
- Lower urgency (quality is less blocking than type errors or test failures)

**Deliverables:**
- Skill implementation with ruff/eslint support
- Integration with `/review-code` and `/fix-code` commands
- Documentation and examples

## Non-Goals

### Not Converting These to Skills

**`/fix-bug`** - Pure investigative reasoning, no clear data processing opportunity

**`/plan`** - Strategic reasoning about implementation approach

**`/fix-docs`** - Creative/contextual work, hard to automate analysis

**`/review-code`** - High-level reasoning about code quality (though can USE analysis skills)

**`/commit`, `/pr-create`** - Already delegate to agents

### Not Creating These Analysis Skills

**`analyzing-git-history`** - Git tools are already efficient, low token savings

**`analyzing-dependencies`** - Complex domain, unclear value, low priority

**`analyzing-security-issues`** - Highly specialized, low frequency, defer

## Key Learnings to Apply

### From MCP Article

1. **Filter in code before returning to Claude** - Analysis skills embody this
2. **Cache processed data, not raw data** - Cache parsed errors, not raw output
3. **Token efficiency is the goal** - Measure savings for each skill

### From Claude Docs Best Practices

1. **Conciseness** - Skill output should be 10-20% of raw tool output
2. **Progressive disclosure** - Basic summary first, details available on request
3. **Deterministic logic** - Tool parsing is perfect use case for code, not LLM

### From Template Implementation

1. **Type hints everywhere** - Makes parsing code reliable
2. **User-friendly errors** - When tool not found, guide installation
3. **Cache by content hash** - Invalidate automatically when files change
4. **Single source of truth** - Tool config determines behavior, not skill config

## Appendix: Token Savings Calculations

### Example: Type Error Analysis

**Raw mypy output:**
```
src/utils.py:42: error: Name "random_seed" is not defined  [no-any-return]
src/utils.py:44: error: Name "random_seed" is not defined  [no-any-return]
src/config.py:15: error: Name "Optional" is not defined  [name-defined]
src/config.py:23: note: Consider importing "Optional" from "typing"
src/models.py:89: error: Argument 1 to "process" has incompatible type "str"; expected "int"  [arg-type]
... (many more lines with full paths, hints, context)
```
Estimated tokens: ~3,500

**Skill summary:**
```markdown
# Type Errors Analysis

**Summary**: 12 errors across 4 files

## By Error Type
### Undefined name (3 errors) - CRITICAL
- src/utils.py:42,44: 'random_seed' [F821]
- src/config.py:15: 'Optional' [F821] → Add: from typing import Optional

### Incompatible types (2 errors) - HIGH
- src/models.py:89: Argument type mismatch (str vs int)
...
```
Estimated tokens: ~400

**Savings**: ~89% (3,500 → 400 tokens)

### Example: Test Failure Analysis

**Raw pytest output:**
```
============================= test session starts ==============================
platform darwin -- Python 3.11.0, pytest-7.4.0, pluggy-1.0.0
collected 152 items

tests/test_auth.py ....F...                                             [ 25%]
tests/test_models.py ..F.                                               [ 50%]
tests/test_utils.py F                                                   [ 75%]
tests/test_service.py .....                                             [100%]

=================================== FAILURES ===================================
_______________________________ test_login_invalid _____________________________

    def test_login_invalid():
        response = client.post("/login", json={"user": "test", "pass": "wrong"})
>       assert response.status_code == 401
E       AssertionError: assert 500 == 401
E        +  where 500 = <Response [500]>.status_code

... (stack traces, context, etc. for each failure)
```
Estimated tokens: ~4,200 (with full traces)

**Skill summary:**
```markdown
# Test Failures: 7 failures, 145 passed

## AssertionError (4 failures)
- test_auth.py::test_login_invalid: Expected 401, got 500
  → Likely uncaught exception in handler
...

## By File
- test_auth.py: 4 failures
- test_models.py: 2 failures
...
```
Estimated tokens: ~350

**Savings**: ~92% (4,200 → 350 tokens)

## Notes for Future Implementer

### You Are Reading This Because...

You've been asked to implement analysis skills that process development tool output. This spec captures the thinking behind the approach.

### Key Context

1. **Why not convert commands to skills?** Commands guide reasoning (Claude's strength), skills process data (code's strength). Keep them separate.

2. **Why these three skills first?** Type errors, test failures, and lint issues are the most token-heavy, most frequently needed, and have the clearest structure for parsing.

3. **Why cache by file hash?** Tool output is deterministic for given file contents. Hash ensures cache invalidates automatically when files change.

4. **Why auto-detect tools?** Following "don't assume installations" pattern - detect what's configured, guide installation if missing.

5. **Why group errors?** Enables Claude to reason about fix strategy systematically rather than treating each error independently.

### Most Important Decisions

1. **Skills process data, commands guide reasoning** - This separation is foundational
2. **Cache processed results, not raw output** - Follows MCP pattern exactly
3. **Start with analyzing-type-errors** - Highest value, clearest structure
4. **Measure token savings** - Validate the approach quantitatively
5. **Integrate with existing commands** - Skills enhance workflows, don't replace them

### If You're Stuck

1. Review the template at `tools/claude/config/skills/@template/`
2. Look at `fetching-github-prs-to-review` for a production example
3. Re-read the MCP article for the "filter in code" principle
4. Remember: 80%+ token savings is the goal - if you're not achieving that, the skill might not be worth it

Good luck! This pattern will unlock proactive analysis capabilities for Claude.
