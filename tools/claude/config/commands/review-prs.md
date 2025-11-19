# Review PRs - Find PRs waiting for my review

Fetch all open PRs where I'm requested as a reviewer across all relevant repos and present them sorted by age.

## Phase 1: Display PRs

Run the `fetch-prs-to-review` skill to fetch and display PRs:

```bash
python3 ~/.claude/skills/fetch-prs-to-review/fetch_prs.py
```

The skill outputs fully formatted markdown ready to display. It handles:

- Fetching from GitHub GraphQL API
- Calculating ages, time estimates, review status
- Formatting each PR with proper spacing
- Grouping into: Feature/Bug PRs → Chores → Dependency Updates
- Sorting by age (oldest first) within each category
- Tracking viewing history (🆕 indicators)
- Storing cache files for PR lookup

**Your task:**

1. Run the skill using the Bash tool
2. Display the skill's output in your text response (copy it directly without modification)
3. The skill output is your complete message - no additional text before or after
4. Do not summarize, analyze, or add commentary - just show the formatted list
5. Create a todo list to track the interactive session:
   - "Waiting for user to select a PR (or 'list')" (pending)
   - "Reviewing PR with enhanced navigation" (pending - will become in_progress when user selects a PR)

## Phase 2: Interactive Session

After Phase 1 completes, enter interactive mode.

**Session State Management:**

Use TodoWrite to maintain session state throughout the workflow. The todo list ensures you remember to return to interactive mode after each PR review completes.

**What the user should see:**

- Formatted PR list (displayed inline in your text response)
- [You waiting silently for input]

**What the user should NOT see:**

- Summaries ("You have 9 PRs waiting...")
- Prompts ("What would you like to do?")
- Commentary about the PRs (the formatted output is self-explanatory)

**IMPORTANT**: The formatted PR list must be displayed inline in your text response, not just in collapsed tool output. Users need to see the list immediately without expanding anything.

**User input options:**

- Type a number (e.g., "7") to review that specific PR
- Type "list" to redisplay the PR queue

**When user types a number:**

1. Update todo: mark "Waiting for user to select a PR" as completed
2. Update todo: mark "Reviewing PR with enhanced navigation" as in_progress
3. Read the mapping from `~/.claude/.cache/fetch-prs-to-review.json`
4. Parse the repo and PR number
5. Fetch PR data: `gh pr view <org>/<repo>#<number> --json title,body,commits,files,url,headRefOid`
6. Get file diffs: `gh pr diff <org>/<repo>#<number>`
7. Review the PR following the Enhanced Review Format (see below)
8. After review, provide Post-Review Action Menu (see below)

## Enhanced Review Format

When reviewing a PR, ALWAYS:

1. **Provide clickable GitHub links for all code references**
   - Format: `[file.py:45-52](https://github.com/<org>/<repo>/blob/<SHA>/file.py#L45-L52)`
   - Use the headRefOid (commit SHA) from PR data for stable links
   - Every code concern must have a clickable link to the exact lines

2. **Show code inline with context**
   ```python
   # auth.py:45-52 → https://github.com/org/repo/blob/abc123/auth.py#L45-L52
   try:
       user = authenticate(token)
   except Exception:
       pass  # ⚠️ Silent error swallowing
   ```

3. **Structure review sections:**
   - **Summary**: One-line PR description
   - **Key Strengths**: What's done well (with links)
   - **Areas of Concern**: Issues requiring attention (with links and inline code)
   - **Questions**: Clarifications needed (with links)
   - **Recommendation**: approve/request-changes/comment

## Post-Review Action Menu

After completing the review, IMMEDIATELY provide this action menu:

```
---
📍 Quick Navigation - Jump to key areas:

1. [Silent error handling](https://://github.com/org/repo/blob/SHA/auth.py#L45-L52) → auth.py:45-52
2. [SQL injection risk](https://github.com/org/repo/blob/SHA/db.py#L103) → db.py:103
3. [Missing rate limit](https://github.com/org/repo/blob/SHA/api.py#L78-L91) → api.py:78-91

🎬 Actions:
a - Approve via gh CLI
c - Request changes via gh CLI
m - Add comment via gh CLI
[1-3] - Open specific concern in browser
n - Next PR (skip posting review)
list - Show full PR queue

What would you like to do?
```

**Action Handlers:**

- **a** → `gh pr review <org>/<repo>#<number> --approve --body "<review summary>"`
- **c** → `gh pr review <org>/<repo>#<number> --request-changes --body "<review summary>"`
- **m** → `gh pr review <org>/<repo>#<number> --comment --body "<review summary>"`
- **[1-3]** → Provide instructions: "Command+click the link above, or copy: [URL]"
- **n** → Mark todo completed, return to PR list with continue prompt
- **list** → Redisplay full PR queue

After posting review via gh CLI, automatically return to PR list navigation.

## Post-Action Return to Queue

After user selects any action from the Post-Review Action Menu:

1. If action was **a/c/m** (posting review):
   - Execute gh CLI command
   - Show success/failure message
   - Mark "Reviewing PR with enhanced navigation" todo as completed
   - Automatically show next steps (don't wait for user input)

2. Calculate remaining PRs from cache
3. Display abbreviated PR list inline
4. Show continue prompt: "Review posted. X remaining. Next: #Y. Continue? (y/n/list/number)"
5. Create new todo: "Waiting for user to select a PR (or 'list')" (pending status)

**Continue options:**
- **y** → Review next PR in sequence
- **n** → Exit interactive session (clear all todos with empty array `[]`)
- **list** → Redisplay full PR list
- **number** → Jump to specific PR by number

**Example enhanced review with action menu:**

```
## PR Review: recursionpharma/auth-service#144 "Add JWT refresh token rotation"

**Summary**: Implements refresh token rotation to improve security of JWT authentication flow.

**Key Strengths**:
- Well-structured token rotation logic in [`auth.py:67-89`](https://github.com/recursionpharma/auth-service/blob/abc123/auth.py#L67-L89)
- Comprehensive test coverage in [`test_auth.py:120-156`](https://github.com/recursionpharma/auth-service/blob/abc123/test_auth.py#L120-L156)

**Areas of Concern**:

1. **Silent error swallowing** in [`auth.py:45-52`](https://github.com/recursionpharma/auth-service/blob/abc123/auth.py#L45-L52):
   ```python
   # auth.py:45-52
   try:
       user = authenticate(token)
   except Exception:
       pass  # ⚠️ This silently swallows all errors
   ```

2. **Potential SQL injection** in [`db.py:103`](https://github.com/recursionpharma/auth-service/blob/abc123/db.py#L103):
   Using string interpolation instead of parameterized queries.

**Recommendation**: Request changes - address error handling and SQL injection before merging.

---
📍 Quick Navigation - Jump to key areas:

1. [Silent error swallowing](https://github.com/recursionpharma/auth-service/blob/abc123/auth.py#L45-L52) → auth.py:45-52
2. [SQL injection risk](https://github.com/recursionpharma/auth-service/blob/abc123/db.py#L103) → db.py:103

🎬 Actions:
a - Approve via gh CLI
c - Request changes via gh CLI
m - Add comment via gh CLI
1-2 - Open specific concern in browser (Command+click link above)
n - Next PR (skip posting review)
list - Show full PR queue

What would you like to do?
```

User then responds with "c" (request changes), and you:
1. Execute: `gh pr review recursionpharma/auth-service#144 --request-changes --body "<summary>"`
2. Show success message
3. Return to PR list with continue prompt

## Cache File Lifecycle

**Location:** `~/.claude/.cache/fetch-prs-to-review.json`

**Behavior:**

- **Created/Overwritten** every time you run `/review-prs`
- Fresh PR data each run (list changes as PRs are merged/created)
- **Read** when you type a number to lookup which PR to review
- Not deleted - persists between runs for quick lookups

**Why overwrite?**

- PR list changes constantly (new PRs, merged PRs, status changes)
- Always want fresh data when starting a review session
- Stale cache from yesterday would show wrong PRs

**Example flow:**

1. Monday 9am: `/review-prs` → Creates cache with 12 PRs
2. You type "7" → Reads cache → Reviews PR #7
3. Monday 2pm: `/review-prs` → **Overwrites** cache with 11 PRs (one merged)
4. You type "3" → Reads fresh cache → Reviews PR #3 (different from morning #3)

## Notes

- This command is **global** - run it from any directory
- It searches across **all organization repos**
- **Automatically filters out** repos specified in the query (e.g., myorg/ignored-repo)
- Uses GraphQL API for private repo access (not `gh search prs`)
- Groups PRs by type: Feature/Bug → Chores → Dependency Updates
- Sorts PRs by age within each group (oldest first)
- **Enhanced review mode** provides:
  - Clickable GitHub links to specific lines of code
  - Inline code snippets with context
  - Post-review action menu (approve/comment/request-changes via gh CLI)
  - Quick navigation to key areas of concern
  - Seamless return to PR queue after posting review
- Cache file is always fresh - run `/review-prs` again if PR list has changed
- Formatting is handled by the skill for consistency

## Implementation Details

The `fetch-prs-to-review` skill (located at `~/.claude/skills/fetch-prs-to-review/`) handles all data fetching and processing:

**What the skill does:**

- Fetches PRs via GitHub GraphQL API
- Calculates ages, time estimates, CI/review/conflict status
- Counts unique reviewers and determines their latest review states
- Groups PRs by category (Feature/Bug → Chores → Dependency Updates)
- Sorts by age (oldest first) within each category
- Formats output as markdown with proper spacing
- Tracks viewing history (🆕 indicators)
- Saves cache files:
  - `~/.claude/.cache/fetch-prs-to-review.json` - PR lookup mapping (seq_num → repo#pr)
  - `~/.claude/.cache/fetch-prs-to-review-history.json` - Viewing history
- Returns formatted markdown ready to display

**What the slash command does:**

- Invokes the skill to fetch and display PR list
- Uses TodoWrite to track session state throughout workflow
- Manages interactive session with y/n/list/number navigation
- When user selects a PR:
  - Fetches PR data via `gh pr view`
  - Analyzes code changes via `gh pr diff`
  - Generates enhanced review with clickable GitHub links to specific lines
  - Shows inline code snippets with context
  - Provides post-review action menu (approve/comment/request-changes)
- Executes gh CLI commands to post reviews directly from terminal
- Automatically returns to PR queue after posting review
- Clears todos when session ends

See `~/.claude/skills/fetch-prs-to-review/SKILL.md` for complete skill documentation.
