---
name: inspecting-codefresh-failures
description: Instruction guide for analyzing Codefresh CI failures. When invoked, IMMEDIATELY follow the step-by-step instructions to extract build IDs, fetch logs, and create a formatted failure report. Use when reviewing recursionpharma PRs with failing CI.
allowed-tools: [Bash, Read]
---

# Inspecting Codefresh Failures

## ⚡ THIS IS AN INSTRUCTION GUIDE - EXECUTE IMMEDIATELY

After invoking this skill, **DO NOT WAIT** - immediately execute the following steps using the PR data you already have:

### QUICK START - Execute Now:

**STEP 1**: Extract build ID from the failing check

- Look for `"state": "FAILURE"` or `"conclusion": "FAILURE"` in statusCheckRollup
- Find the Codefresh URL in `targetUrl` or `detailsUrl`
- Extract the build ID (24-char hex) from `https://g.codefresh.io/build/{build-id}`

**STEP 2**: Fetch build metadata

```bash
codefresh get builds <build-id> -o json
```

**STEP 3**: Search logs for errors

```bash
codefresh logs <build-id> | grep -E -B 10 -A 20 -i "error|fail|found.*error"
```

**STEP 4**: Format your findings using the "Expected Output Format" template below

**STEP 5**: Include the formatted report in your PR review under "## CI Failure Analysis"

---

## Detailed Instructions

This skill provides step-by-step guidance for analyzing Codefresh CI failures in recursionpharma organization repositories.

## Prerequisites

**Required:**

- `codefresh` CLI must be installed (typically via Homebrew: `brew install codefresh`)
- User must be authenticated with Codefresh (check with `codefresh auth current-context`)

**If prerequisites are missing:**

- Inform the user that the Codefresh CLI is not available
- Suggest they install it: `brew install codefresh`
- Provide alternative: manually check the Codefresh build URL in the browser

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

# Search for errors (most efficient - use multiple patterns)
codefresh logs <build-id> | grep -E -B 10 -A 20 -i "error\|fail\|found.*error"

# Common error patterns to look for:
# - "Found N errors" (linting/type checking)
# - "FAILED" or "FAILURE" (test results)
# - "Error:" or "ERROR:" (build errors)
# - "exit code" (non-zero exit codes)
```

## Error Handling

If the `codefresh` command is not available:

```bash
# Check if codefresh is installed
which codefresh || echo "Codefresh CLI not installed"

# If not installed, inform user and provide fallback:
# "The codefresh CLI is not installed. You can:
# 1. Install it: brew install codefresh
# 2. View the build in browser: [build URL from status check]"
```

## Expected Output Format

Returns markdown-formatted analysis ready to include in PR reviews or bug reports:

```markdown
## CI Failure Analysis

**Build**: python/library (failed after 5m 2s)
**Failed step**: Check Code with Ruff
**Branch**: legion-2025-03-04-f8ef390a
**Commit**: abc1234...

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

Pre-existing code quality issues exposed by recent infrastructure changes (such as updates to dependency sources). The changes only modify dependency sources in files like `Dockerfile.test` and `tox.ini`, not application code.

### Recommendation

Request changes - fix the 5 undefined `random_seed` errors before merging (critical runtime bugs). Other linting issues can be addressed in a follow-up PR.
```

## Notes

- **Only works for recursionpharma org repos** - Codefresh is their CI system
- **Build IDs are unique** - Each build has a unique 24-character hex ID
- **Logs can be large** - Use grep patterns to find relevant errors quickly (logs can exceed 30k lines)
- **Context matters** - Always distinguish PR-introduced errors from pre-existing issues
- **Tested and verified** - Commands tested against build `67c7469b3275b6f1b9f96f69` (recursionpharma/phenomics-potency-prediction#2)

**Common error patterns:**

- Linting errors (Ruff, Flake8, Black) - Look for "Found N errors"
- Type errors (mypy, pyright) - Look for "error:" in output
- Test failures (pytest, unittest) - Look for "FAILED" or "FAILURE"
- Build failures (missing dependencies, import errors) - Look for "Error:" or "exit code"
- Security scans (dependency vulnerabilities) - Check specific security step logs

---

## 🔴 IMPORTANT REMINDERS

**You are reading this skill because you are reviewing a PR with failing CI.**

**RIGHT NOW, you should:**

1. ✅ Have already fetched the PR data with `gh pr view <number> --json statusCheckRollup`
2. ✅ See failing checks in that data with `"state": "FAILURE"` or `"conclusion": "FAILURE"`
3. ⚠️ **NEXT**: Extract the build ID from the Codefresh URL and run the commands above
4. ⚠️ **DO NOT**: Wait, ask questions, or pause - execute the steps immediately
5. ⚠️ **GOAL**: Create a "## CI Failure Analysis" section in your PR review with specific errors

**If you find yourself waiting or unsure what to do next, re-read the QUICK START section at the top.**
