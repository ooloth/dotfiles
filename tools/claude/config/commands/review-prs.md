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
   - "Reviewing PR with enhanced navigation" (pending)

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
5. Fetch PR data with context: `gh pr view <number> --repo <org>/<repo> --json title,body,commits,files,url,headRefOid,reviews,comments,statusCheckRollup`
6. Get file diffs: `gh pr diff <number> --repo <org>/<repo>`
7. Process existing review context (see Existing Review Context section below)
8. **For recursionpharma repos**: Check for CI failures and investigate using Codefresh CLI (see CI Failure Investigation section below)
9. Review the PR following the Enhanced Review Format (see below)
10. After review, provide Post-Review Action Menu (see below)

## Existing Review Context

Before analyzing the PR yourself, process existing review context to avoid duplicating feedback:

**Parse reviews and comments from the PR data:**

- Extract all review comments (inline and general)
- Extract all conversation comments
- Group by file and line number
- Identify discussion themes

**Display context section at the start of your review:**

```
📝 Existing Review Activity:

@alice reviewed 2 days ago (CHANGES_REQUESTED):
- auth.py:45-52: "Should log errors instead of swallowing"
- db.py:103: "Use parameterized queries"

@bob commented 1 day ago:
- General: "Looks good overall, just those two issues to address"

💬 Active discussions (3):
- auth.py:45-52: Error handling approach (2 comments)
- db.py:103: SQL injection fix (1 comment)
- test_auth.py:89: Test coverage question (3 comments, ongoing)
```

**In your review:**

- Note which concerns already have feedback (skip or add +1)
- Identify new issues not yet mentioned
- Join ongoing discussions if you have additional insight
- Avoid repeating what others already said clearly

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

## CI Failure Investigation (recursionpharma repos only)

When reviewing a recursionpharma PR with failing CI, **ALWAYS** investigate the failure.

**Use the `inspect-codefresh-failure` skill** - it will extract build IDs from status checks, fetch logs, identify errors, and provide a formatted analysis report.

Include the skill's output in your review under a "CI Failure Analysis" section.

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

**Step 3: AI-Assisted Comment Drafting**

Show the code snippet again with context, then suggest comment templates:

```
Code at auth.py:45-52:
   try:
       user = authenticate(token)
   except Exception:
       pass

💡 Suggested comments (or write your own):
1. "I'm curious about the exception handling here. What happens when authentication fails? Should we be logging this or letting it propagate?"
2. "How do we want to handle the case where authenticate() raises an exception? I'm wondering if silent failure here could make debugging harder later."
3. "What's the intended behavior when authentication fails? Should this return None, raise a specific error, or log for monitoring?"

Select 1-3 to edit, or press Enter to write custom comment:
>
```

**How to generate suggestions:**
Based on the issue type, offer socratic, mentor-like templates that lead with curiosity:

- **Silent error handling**: "I'm curious about...", "What happens when...", "How should we handle..."
- **SQL injection**: "I'm wondering if...", "Have we considered...", "What would happen if..."
- **Missing tests**: "How can we verify...", "What edge cases should we consider...", "I'm curious how this behaves when..."
- **Security concern**: "I'm wondering about security here...", "What happens if a user...", "Have we thought about..."
- **Performance**: "I'm curious about the performance implications...", "How does this scale when...", "Have we measured..."
- **Code clarity**: "I'm finding this a bit hard to follow...", "Could we clarify...", "What's the reasoning behind..."

Use full sentences, ask genuine questions, and frame as collaborative exploration rather than directives.

**Step 4: User responds**

If they select a number (1-3):

- Show that suggestion pre-filled for editing
- They can modify or use as-is

If they press Enter or type text:

- Use their custom comment

Store the final comment with file, line number, and body.

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
Build the API request using `--input -` with a heredoc (the `-f` flag doesn't support JSON arrays):

```bash
gh api repos/<org>/<repo>/pulls/<number>/reviews \
  --method POST \
  --input - <<'EOF'
{
  "body": "<review summary from earlier>",
  "event": "<APPROVE|REQUEST_CHANGES|COMMENT>",
  "comments": [
    {
      "path": "auth.py",
      "line": 52,
      "body": "..."
    },
    {
      "path": "db.py",
      "line": 103,
      "body": "..."
    }
  ]
}
EOF
```

Notes:

- Use `--input -` with heredoc for complex JSON payloads (the `-f` flag is for individual fields and doesn't support complex JSON structures like arrays)
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

````
## PR Review: recursionpharma/auth-service#144 "Add JWT refresh token rotation"

📝 Existing Review Activity:

@alice reviewed 2 days ago (CHANGES_REQUESTED):
- auth.py:45-52: "Should log errors instead of swallowing"
- db.py:103: "Use parameterized queries"

💬 Active discussions (2):
- auth.py:45-52: Error handling approach (2 comments)
- db.py:103: SQL injection fix (1 comment)

---

**Summary**: Implements refresh token rotation to improve security of JWT authentication flow.

**Key Strengths**:
- Well-structured token rotation logic in `auth.py:67-89`
- Comprehensive test coverage in `test_auth.py:120-156`

**New Issues** (not mentioned in existing reviews):

1. **Missing token expiry validation** in `auth.py:78`:
   ```python
   # auth.py:78
   new_token = generate_refresh_token(user)
   # ⚠️ No check if old token has expired
````

**Previously Identified** (joining discussion):

- auth.py:45-52: Error handling (alice mentioned logging)
- db.py:103: SQL injection (alice mentioned parameterized queries)

**Recommendation**: Request changes - address new expiry validation issue. Existing issues already have good feedback from alice.

---

📍 Key areas to review:

- auth.py:78 - Missing token expiry validation (NEW)
- auth.py:45-52 - Silent error swallowing (alice +1)
- db.py:103 - SQL injection risk (alice +1)

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

**Option B: Add inline comments with AI assistance:**
1. Read review in terminal (see existing feedback from alice)
2. Type "i" to add inline comments
3. Select "1" for auth.py:78 (the NEW issue you found)
4. See AI-suggested comments:
   - Option 1: "I'm curious about the token expiry validation here. What happens if a user requests a refresh with an already-expired token?"
   - Option 2: "How are we handling the case where old_token has expired? I'm wondering if this could be a security concern."
   - Option 3: "Should we validate that old_token hasn't expired before issuing a new one? What's the intended behavior here?"
5. Select "1" to use first suggestion (or edit it, or write custom)
6. Select "y" to add another
7. Select "2" for auth.py:45-52 (alice already commented)
8. Type custom: "Agree with alice's point about logging. I'm also curious if we should handle specific exception types differently here."
9. Select "n" when done
10. Type "c" to submit as request changes with 2 inline comments
11. Automatically return to PR list with continue prompt

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
  - **Existing review context**: See what others have already commented on to avoid duplication
  - Inline code snippets with context and file:line references
  - Post-review action menu with multiple options
  - **AI-assisted comment drafting**: Get suggested comments based on issue type, edit or use as-is
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
  - Fetches PR data with reviews and comments via `gh pr view --json reviews,comments,...`
  - Analyzes code changes via `gh pr diff`
  - **Displays existing review context** (who reviewed, what they said, active discussions)
  - Generates enhanced review avoiding duplication of existing feedback
  - Shows inline code snippets with file:line references
  - Provides post-review action menu (o/i/a/c/n/l)
- Post-review actions:
  - **o**: Opens PR in browser
  - **i**: Interactive inline comment builder with **AI-assisted suggestions** (attaches comments to specific lines via gh api)
  - **a/c**: Posts general review via gh CLI (approve/request changes)
  - **n**: Skip to next PR
  - **l**: Redisplay full queue
- Automatically returns to PR queue after posting review
- Clears todos when session ends

See `~/.claude/skills/fetch-prs-to-review/SKILL.md` for complete skill documentation.
```
