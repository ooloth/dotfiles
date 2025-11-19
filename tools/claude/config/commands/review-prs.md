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
   - "Waiting for user to select a PR (or 'list')"
   - "After /review completes, return to interactive mode"

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
2. Update todo: mark "After /review completes, return to interactive mode" as in_progress
3. Read the mapping from `~/.claude/.cache/fetch-prs-to-review.json`
4. Parse the repo and PR number
5. Launch `/review <org>/<repo>#<number>`
6. After /review completes, wait for user to send any message to continue

**When user sends next message after /review completes:**

You are still in the review-prs session. You MUST immediately:

1. Check your todos - you have one in_progress: "After /review completes, return to interactive mode"
2. Mark that todo as completed
3. Read the mapping from `~/.claude/.cache/fetch-prs-to-review.json` to calculate remaining PRs
4. Determine the next PR number in sequence
5. Display abbreviated PR list inline in your text response
6. End your message with: "Review complete. X remaining. Next: #Y. Continue? (y/n/list/number)"
7. Create new todo: "Waiting for user to select a PR (or 'list')" (pending status)
8. Wait for user response

Note: Due to conversation turn-taking, user must send any message (even just "thanks") to trigger the next turn. When they do, immediately return to interactive mode as described above.

**Response options:**

- "y" → Review next PR in sequence (update todos and launch /review)
- "n" → Exit interactive session (clear all todos with empty array)
- "list" → Redisplay full PR list (keep current todos)
- number → Jump to specific PR by number (update todos and launch /review)

**Continue the loop** until user chooses to exit with "n"

When user exits:
- Clear the todo list: `TodoWrite` with empty todos array `[]`
- Confirm session ended

**Example post-review response:**

```
## PR Review: #144 "Use prototype trekseq"

[... your review content ...]

---

📋 PRs waiting for your review: 8 remaining | Est. time: ~1h 30min

⚠️ ACTION REQUIRED (2):

 1. **"Bump jinja2 from 3.1.4 to 3.1.6" • template-javascript-react • @dependabot**
   • 📅 8 months old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +2  🔴 -2  📄 2 files  ⏱️ ~5 min
   • 🔗 https://github.com/recursionpharma/template-javascript-react/pull/63

 2. **"Introduce Docker-less dev environment" • rp006-brnaseq-analysis-flow • @jackdhaynes**
   • 💬 Replaces the existing Docker compose-based dev environment setup with a Docker-less one
   • 📅 5 months old • ⏸️ Draft • 👀 Review required • ⚠️ Conflicts
   • 🟢 +16  🔴 -225  📄 11 files  ⏱️ ~20 min
   • 🔗 https://github.com/recursionpharma/rp006-brnaseq-analysis-flow/pull/2

🎯 HIGH PRIORITY - Feature/Bug PRs (1):

 4. **"Add cell neighborhood table" • cell-sight • @marianna-trapotsi-rxrx**
   • 💬 Added patient-derived information; cell neighborhood table
   • 📅 1 day old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +76  🔴 -45  📄 6 files  ⏱️ ~10 min
   • 🔗 https://github.com/recursionpharma/cell-sight/pull/39

🤖 DEPENDABOT - Dependency Updates (5):
[... abbreviated list ...]

---

**Review complete.** 8 remaining. Next: #4 "Add cell neighborhood table"

Continue? (y/n/list/number)
```

Note: The navigation prompt at the end allows the user to easily continue to the next PR, jump to a specific PR, or redisplay the full list.

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
- Works seamlessly with the built-in `/review <org>/<repo>#<number>` command
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

- Invokes the skill
- Displays the skill's markdown output
- Uses TodoWrite to track session state (ensures return to interactive mode after reviews)
- Manages interactive session (y/n/list/number navigation)
- Launches `/review` when user selects a PR
- Clears todos when session ends

See `~/.claude/skills/fetch-prs-to-review/SKILL.md` for complete skill documentation.
