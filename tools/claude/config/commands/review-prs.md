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
   - "Waiting for user to select a PR (or 'l')" (pending)
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
- Type "l" to redisplay the PR queue

**When user types a number:**

1. Update todo: mark "Waiting for user to select a PR" as completed
2. Update todo: mark "Reviewing PR with enhanced navigation" as in_progress
3. Read the mapping from `~/.claude/.cache/fetch-prs-to-review.json`
4. Parse the repo and PR number
5. Fetch PR data: `gh pr view <number> --repo <org>/<repo> --json title,body,commits,files,url,headRefOid`
6. Get file diffs: `gh pr diff <number> --repo <org>/<repo>`
7. Review the PR following the Enhanced Review Format (see below)
8. After review, provide Post-Review Action Menu (see below)

## Enhanced Review Format

When reviewing a PR, ALWAYS:

1. **Reference files and line numbers clearly**
   - Format: `auth.py:45-52` (file path with line numbers)
   - Every code concern must specify the file and line numbers
   - No clickable links needed - user will use "o" action to open PR in browser

2. **Show code inline with context**
   ```python
   # auth.py:45-52
   try:
       user = authenticate(token)
   except Exception:
       pass  # ⚠️ Silent error swallowing
   ```

3. **Structure review sections:**
   - **Summary**: One-line PR description
   - **Key Strengths**: What's done well (with file:line references)
   - **Areas of Concern**: Issues requiring attention (with file:line references and inline code)
   - **Questions**: Clarifications needed (with file:line references)
   - **Recommendation**: approve/request-changes/comment

## Post-Review Action Menu

After completing the review, IMMEDIATELY provide this action menu:

```
---
📍 Key areas to review:
- auth.py:45-52 - Silent error swallowing
- db.py:103 - SQL injection risk
- api.py:78-91 - Missing rate limit

🎬 Actions:
o - Open PR in browser
i - Add inline comments (interactive)
a - Approve via gh CLI (general comment only)
c - Request changes via gh CLI (general comment only)
n - Next PR (skip posting review)
l - Show full PR queue

What would you like to do?
```

**Action Handlers:**

- **o** → Open PR in browser: `open https://github.com/<org>/<repo>/pull/<number>`
- **i** → Interactive inline comment builder (see below)
- **a** → `gh pr review <number> --repo <org>/<repo> --approve --body "<review summary>"`
- **c** → `gh pr review <number> --repo <org>/<repo> --request-changes --body "<review summary>"`
- **n** → Mark todo completed, return to PR list with continue prompt
- **l** → Redisplay full PR queue

After posting review via gh CLI, automatically return to PR list navigation.

## Interactive Inline Comment Builder

When user selects "i", start an interactive flow to build inline comments:

**Step 1: Prompt for location**
```
Add inline comment to which area?
1. auth.py:45-52 - Silent error swallowing
2. db.py:103 - SQL injection risk
3. api.py:78-91 - Missing rate limit
Or type file:line (e.g., "utils.py:23")
>
```

**Step 2: User selects location (e.g., "1")**
Parse their input:
- If number: Use the corresponding file:line from key areas list
- If file:line format: Use that directly
- Extract file path and line number

**Step 3: Prompt for comment**
```
Comment for auth.py:45-52:
>
```

**Step 4: User enters comment**
Store the comment with file, line number, and body.

**Step 5: Ask to continue**
```
Inline comment added. Add another? (y/n)
>
```

If "y", repeat from Step 1.
If "n", proceed to Step 6.

**Step 6: Show summary and ask for review type**
```
Review with 2 inline comments:
1. auth.py:45-52: "This should log the error instead of silently swallowing it"
2. db.py:103: "Use parameterized queries to prevent SQL injection"

Submit as: (a)pprove, (c)hange requests, or co(m)ment?
>
```

**Step 7: Submit via GitHub API**
Build the API request:
```bash
gh api repos/<org>/<repo>/pulls/<number>/reviews \
  -f body="<review summary from earlier>" \
  -f event="<APPROVE|REQUEST_CHANGES|COMMENT>" \
  -f 'comments=[
    {"path":"auth.py","line":52,"body":"..."},
    {"path":"db.py","line":103,"body":"..."}
  ]'
```

Notes:
- Use the line number as the ending line for each range
- The "path" should be relative to repo root
- "body" field is the overall review summary from the initial review
- "event" maps to: a→APPROVE, c→REQUEST_CHANGES, m→COMMENT

After successful submission, return to PR list navigation.

## Post-Action Return to Queue

After user selects any action from the Post-Review Action Menu:

1. If action was **a/c** (posting review without inline comments):
   - Execute gh CLI command
   - Show success/failure message
   - Mark "Reviewing PR with enhanced navigation" todo as completed
   - Automatically show next steps (don't wait for user input)

2. If action was **i** (inline comments):
   - Follow Interactive Inline Comment Builder flow
   - After submitting via gh api, show success/failure message
   - Mark "Reviewing PR with enhanced navigation" todo as completed
   - Automatically show next steps (don't wait for user input)

3. Calculate remaining PRs from cache
4. Display abbreviated PR list inline
5. Show continue prompt: "Review posted. X remaining. Next: #Y. Continue? (y/n/l/number)"
6. Create new todo: "Waiting for user to select a PR (or 'l')" (pending status)

**Continue options:**
- **y** → Review next PR in sequence
- **n** → Exit interactive session (clear all todos with empty array `[]`)
- **l** → Redisplay full PR list
- **number** → Jump to specific PR by number

**Example enhanced review with action menu:**

```
## PR Review: recursionpharma/auth-service#144 "Add JWT refresh token rotation"

**Summary**: Implements refresh token rotation to improve security of JWT authentication flow.

**Key Strengths**:
- Well-structured token rotation logic in `auth.py:67-89`
- Comprehensive test coverage in `test_auth.py:120-156`

**Areas of Concern**:

1. **Silent error swallowing** in `auth.py:45-52`:
   ```python
   # auth.py:45-52
   try:
       user = authenticate(token)
   except Exception:
       pass  # ⚠️ This silently swallows all errors
   ```

2. **Potential SQL injection** in `db.py:103`:
   ```python
   # db.py:103
   query = f"SELECT * FROM users WHERE id = {user_id}"  # ⚠️ SQL injection risk
   ```

**Recommendation**: Request changes - address error handling and SQL injection before merging.

---
📍 Key areas to review:
- auth.py:45-52 - Silent error swallowing
- db.py:103 - SQL injection risk

🎬 Actions:
o - Open PR in browser
i - Add inline comments (interactive)
a - Approve via gh CLI (general comment only)
c - Request changes via gh CLI (general comment only)
n - Next PR (skip posting review)
l - Show full PR queue

What would you like to do?
```

**User workflow examples:**

**Option A: Review in browser, then post general review via CLI:**
1. Read review in terminal
2. Type "o" to open PR in browser
3. Navigate to Files changed tab, review code
4. Return to terminal, type "c" to request changes via gh CLI
5. Automatically return to PR list with continue prompt

**Option B: Add inline comments interactively:**
1. Read review in terminal
2. Type "i" to add inline comments
3. Select "1" for auth.py:45-52
4. Enter comment: "This should log the error instead of silently swallowing it"
5. Select "y" to add another
6. Select "2" for db.py:103
7. Enter comment: "Use parameterized queries to prevent SQL injection"
8. Select "n" when done
9. Type "c" to submit as request changes with inline comments
10. Automatically return to PR list with continue prompt

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
  - Inline code snippets with context and file:line references
  - Post-review action menu with multiple options
  - Interactive inline comment builder for attaching comments to specific lines
  - Quick browser navigation to PR (via "o" action)
  - General review posting via gh CLI (via "a"/"c" actions)
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
- Manages interactive session with y/n/l/number navigation
- When user selects a PR:
  - Fetches PR data via `gh pr view`
  - Analyzes code changes via `gh pr diff`
  - Generates enhanced review with file:line references
  - Shows inline code snippets with context
  - Provides post-review action menu (o/i/a/c/n/l)
- Post-review actions:
  - **o**: Opens PR in browser
  - **i**: Interactive inline comment builder (attaches comments to specific lines via gh api)
  - **a/c**: Posts general review via gh CLI (approve/request changes)
  - **n**: Skip to next PR
  - **l**: Redisplay full queue
- Automatically returns to PR queue after posting review
- Clears todos when session ends

See `~/.claude/skills/fetch-prs-to-review/SKILL.md` for complete skill documentation.
