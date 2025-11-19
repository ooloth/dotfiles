---
name: inspect-codefresh-failure
description: Inspects Codefresh CI build failures for recursionpharma org repos. Extracts build ID from status checks, fetches logs, and identifies specific errors with file/line references. Use when you see failing CI in a recursionpharma PR or when debugging CI-related issues.
allowed-tools: [Bash, Read]
---

# Inspect Codefresh Failure Skill

Analyzes Codefresh CI failures for recursionpharma organization repositories and provides detailed failure reports with specific errors and root cause analysis.

## When to Use This Skill

Use this skill when:
- You see a failing CI check in a recursionpharma PR
- User mentions CI failures in recursionpharma repos
- Debugging "passes locally but fails in CI" issues
- Investigating build failures from Codefresh

## What This Skill Does

1. **Accepts input**:
   - Build ID directly (e.g., `67c7469b3275b6f1b9f96f69`)
   - PR context with `statusCheckRollup` containing Codefresh URL
   - Repository and PR number (will fetch status checks)

2. **Analyzes the failure**:
   - Fetches build metadata via `codefresh get builds <build-id> -o json`
   - Retrieves full logs via `codefresh logs <build-id>`
   - Searches for error patterns in logs
   - Identifies failed step and specific error messages

3. **Returns structured report** with:
   - Build metadata (pipeline, duration, status, branch)
   - Failed step name
   - Specific error messages with file:line references
   - Root cause analysis
   - Impact assessment (critical vs non-blocking)
   - Whether errors are from PR changes or pre-existing

## Usage Examples

### Example 1: From Build ID
```bash
# If you already have the build ID
Build ID: 67c7469b3275b6f1b9f96f69
```

### Example 2: From PR Status Check Data
```json
{
  "statusCheckRollup": [
    {
      "__typename": "StatusContext",
      "context": "python/library",
      "state": "FAILURE",
      "targetUrl": "https://g.codefresh.io/build/67c7469b3275b6f1b9f96f69"
    }
  ]
}
```

### Example 3: From Repository and PR Number
```bash
# Will fetch status checks and extract build ID
Repository: recursionpharma/phenomics-potency-prediction
PR Number: 2
```

## How to Extract Build ID

From PR JSON data (`gh pr view --json statusCheckRollup`):

1. Look for failing checks:
   - `"state": "FAILURE"` (StatusContext)
   - `"conclusion": "FAILURE"` (CheckRun)

2. Find Codefresh URLs in:
   - `targetUrl` field (StatusContext)
   - `detailsUrl` field (CheckRun)

3. Extract build ID from URL:
   - Format: `https://g.codefresh.io/build/{build-id}`
   - Example: `67c7469b3275b6f1b9f96f69`

## Commands Used

```bash
# Get build metadata
codefresh get builds <build-id> -o json

# Get full logs
codefresh logs <build-id>

# Search for errors (most efficient)
codefresh logs <build-id> | grep -B 10 -A 20 -i "error\|fail\|found.*errors"
```

## Expected Output Format

Returns markdown-formatted analysis ready to include in PR reviews or bug reports:

```markdown
## CI Failure Analysis

**Build**: python/library (failed after 5m 2s)
**Failed step**: Check Code with Ruff
**Branch**: legion-2025-03-04-f8ef390a
**Commit**: 30c64522355a1616d6e3d0a7a4307625ccc38452

### Errors Found (10 total)

1. **`phenomics_potency_prediction/utils.py:331,333,365,367,369`**
   - Undefined name `random_seed` (5 occurrences)
   - **Impact**: Likely runtime errors - CRITICAL to fix
   - **Type**: F821 (undefined name)

2. **`phenomics_potency_prediction/gene-cossim-curvefit/parallel-curvefit.py:233`**
   - Line too long (3373 characters > 120 limit)
   - **Impact**: Code quality issue - non-blocking
   - **Type**: E501 (line too long)

3. **`parallel-curvefit.py:139,275`**
   - Bare `except` clauses (2 occurrences)
   - **Impact**: Poor error handling - should specify exception types
   - **Type**: E722 (bare except)

### Root Cause

Pre-existing code quality issues exposed by this PR's infrastructure change (switching from Nexus to Google Artifact Registry). The PR itself only modifies dependency sources in `Dockerfile.test` and `tox.ini`, not application code.

### Recommendation

Request changes - fix the 5 undefined `random_seed` errors before merging (critical runtime bugs). Other linting issues can be addressed in a follow-up PR.
```

## Notes

- **Only works for recursionpharma org repos** - Codefresh is their CI system
- **Build IDs are unique** - Each build has a unique 24-character hex ID
- **Logs can be large** - Use grep patterns to find relevant errors quickly
- **Context matters** - Always distinguish PR-introduced errors from pre-existing issues
- **Common error patterns**:
  - Linting errors (Ruff, Flake8, Black)
  - Type errors (mypy, pyright)
  - Test failures (pytest, unittest)
  - Build failures (missing dependencies, import errors)
  - Security scans (dependency vulnerabilities)
