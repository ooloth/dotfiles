# Review Queue - Find PRs waiting for my review

Fetch all open PRs where I'm requested as a reviewer across all relevant repos and present them sorted by age.

## Phase 1: Display PRs

Run the `review-queue` skill to fetch and display PRs:

```bash
python3 ~/.claude/skills/review-queue/fetch_prs.py
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
2. Display the skill's output directly in your response (no additional formatting or commentary)
3. The skill output is your complete message

## Phase 2: Interactive Session

After Phase 1 completes, enter interactive mode.

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

- Read the mapping from `~/.claude/.cache/review-queue.json`
- Parse the repo and PR number
- Launch `/pr-review <number> --repo <org>/<repo>`

**After each PR review completes:**

1. Update the cache with review completion timestamp
2. Calculate remaining PRs and next PR in sequence
3. Display the abbreviated PR list inline (not in collapsed tool output)
4. End your message with the navigation prompt: "Review complete. X remaining. Next: #Y. Continue? (y/n/list/number)"

**Response options:**

- "y" → Review next PR in sequence
- "n" → Exit interactive session
- "list" → Redisplay full PR list
- number → Jump to specific PR by number

**Continue the loop** until user chooses to exit with "n"

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

**Location:** `~/.claude/.cache/review-queue.json`

**Behavior:**

- **Created/Overwritten** every time you run `/review-queue`
- Fresh PR data each run (list changes as PRs are merged/created)
- **Read** when you type a number to lookup which PR to review
- Not deleted - persists between runs for quick lookups

**Why overwrite?**

- PR list changes constantly (new PRs, merged PRs, status changes)
- Always want fresh data when starting a review session
- Stale cache from yesterday would show wrong PRs

**Example flow:**

1. Monday 9am: `/review-queue` → Creates cache with 12 PRs
2. You type "7" → Reads cache → Reviews PR #7
3. Monday 2pm: `/review-queue` → **Overwrites** cache with 11 PRs (one merged)
4. You type "3" → Reads fresh cache → Reviews PR #3 (different from morning #3)

## Notes

- This command is **global** - run it from any directory
- It searches across **all organization repos**
- **Automatically filters out** repos specified in the query (e.g., myorg/ignored-repo)
- Uses GraphQL API for private repo access (not `gh search prs`)
- Groups PRs by type: Feature/Bug → Chores → Dependency Updates
- Sorts PRs by age within each group (oldest first)
- Works seamlessly with the existing `/pr-review <number> --repo <org>/<repo>` command
- Cache file is always fresh - run `/review-queue` again if PR list has changed
- Formatting is handled by the skill for consistency

## Implementation Details

The `review-queue` skill (located at `~/.claude/skills/review-queue/`) handles all data fetching and processing:

**What the skill does:**

- Fetches PRs via GitHub GraphQL API
- Calculates ages, time estimates, CI/review/conflict status
- Counts unique reviewers and determines their latest review states
- Groups PRs by category (Feature/Bug → Chores → Dependency Updates)
- Sorts by age (oldest first) within each category
- Formats output as markdown with proper spacing
- Tracks viewing history (🆕 indicators)
- Saves cache files:
  - `~/.claude/.cache/review-queue.json` - PR lookup mapping (seq_num → repo#pr)
  - `~/.claude/.cache/review-queue-history.json` - Viewing history
- Returns formatted markdown ready to display

**What the slash command does:**

- Invokes the skill
- Displays the skill's markdown output
- Manages interactive session (y/n/list/number navigation)
- Launches `/pr-review` when user selects a PR

See `~/.claude/skills/review-queue/SKILL.md` for complete skill documentation.
