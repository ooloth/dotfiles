# Review Queue - Find PRs waiting for my review

Fetch all open PRs where I'm requested as a reviewer across all relevant repos and present them in priority order to be reviewed.

## Phase 1: Fetch PR Data

Use the `review-queue` skill to fetch and process PR data:

```bash
python3 ~/.claude/skills/review-queue/fetch_prs.py
```

This returns structured JSON with all PRs grouped and prioritized. The skill handles:

- Fetching from GitHub GraphQL API
- Calculating ages, time estimates, review status
- Grouping by priority (ACTION REQUIRED, HIGH PRIORITY, DEPENDABOT, CHORES)
- Tracking viewing history (🆕 indicators)
- Storing cache files

## Phase 2: Display PRs

The skill returns JSON with PRs already grouped into categories:

- **ACTION REQUIRED** - Urgent items (failing CI, very old >6mo, conflicts on old PRs)
- **HIGH PRIORITY** - Feature/Bug PRs (not chores, not dependabot)
- **DEPENDABOT** - Automated dependency updates
- **CHORES** - Infrastructure/config changes (title starts with "chore:")

**Your task:**

1. Parse the JSON from the skill
2. Format each PR using the exact template (see "Output Formatting" section below)
3. **IMPORTANT**: Display the formatted output inline in your text response (not just in tool output)
4. The formatted output should be your complete message - no additional commentary
5. Show available commands at the end

## Phase 3: Interactive Session

After Phase 2 completes, enter interactive mode.

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

## Output Formatting

Present all results using the exact template structure shown below. The template defines the required format, spacing, emojis, and field order for each PR entry. Do not improvise variations.

## Required Output Format Template

Use this exact template for each PR. Preserve spacing, emojis, and structure precisely:

```
 {number}. {new_badge}**"{title}" • {repo_short} • @{author}**
   • 💬 {summary}
   • {age_str} • {ci_status} • {review_status} • {conflict_status}
   • {engagement_line}
   • {urgency_line}
   • 🟢 +{additions}  🔴 -{deletions}  📄 {files} files  ⏱️ {time_estimate}
   • 🔗 {url}

```

**Field definitions:**

- `{number}`: PR sequence number (1-N) - **MUST start with a space** (e.g., " 1.") to prevent markdown list parsing
- Lines starting with bullet points must have 3 regular spaces before the bullet to preserve indentation
- `{new_badge}`: "🆕 " if PR not in history, otherwise empty string
- `{title}`: PR title in quotes
- `{repo_short}`: Repository name without organization prefix (no #PR_NUMBER)
- `{author}`: Author's GitHub username with @ prefix (always include, even for dependabot PRs which will show "@dependabot")
- First line must be wrapped in `**bold**` markdown
- `{summary}`: First meaningful line from PR description (omit line if empty) - appears first in bullet list
- `{additions}`: Number of lines added (shown with 🟢 emoji)
- `{deletions}`: Number of lines deleted (shown with 🔴 emoji)
- `{files}`: Number of files changed (shown with 📄 emoji)
- `{time_estimate}`: "~5 min", "~10 min", "~20 min", "~30 min", or "~45 min" (shown with ⏱️ emoji)
- `{age_str}`: Natural phrasing with emoji: "📅 1 day old", "📅 4 days old", "📅 5 months old", "📅 1 week old", etc.
- `{ci_status}`: Natural phrasing with emoji: "✅ CI passing", "❌ CI failing", "⏸️ Draft", or "⏳ CI pending"
- `{review_status}`: Natural phrasing with emoji, format varies:
  - Simple: "✅ Approved", "👀 Review required", "⚠️ Changes requested"
  - With reviewers: "👥 {count} reviewers" (e.g., "👥 2 reviewers", "👥 3 reviewers")
  - Count represents unique human reviewers (excluding bots)
  - Breakdown shows each reviewer's most recent review state (e.g., "👥 3 reviewers (✅ 1 approved, 💬 2 commented)")
- `{conflict_status}`: Natural phrasing with emoji: "✅ No conflicts" or "⚠️ Conflicts"
- `{engagement_line}`: Your engagement status (omit line if none):
  - " 💬 You commented {age} ago"
  - " ✅ You approved {age} ago"
  - " ⚠️ You requested changes {age} ago"
- `{urgency_line}`: Reason for urgency in ACTION REQUIRED section (omit elsewhere):
  - " ⚠️ {reason} - needs immediate attention"
- `{url}`: Plain URL (no ANSI codes) - terminal will auto-detect and color links

## Annotated Format Examples

These examples highlight specific formatting requirements:

**Review status with multiple reviewers** - Note the required emoji prefixes and unique reviewer count:

```
👥 3 reviewers (✅ 1 approved, 💬 2 commented)
                ^^             ^^
              Required emoji prefixes for each count type
              Breakdown shows each reviewer's most recent state
```

**Complete PR entry** - Note spacing and optional lines:

```
 4. 🆕 **"Add user authentication" • frontend-app • @alice**
   • 💬 Implements JWT-based authentication for API endpoints
   • 📅 1 day old • ✅ CI passing • 👀 Review required • 👥 3 reviewers • ✅ No conflicts
   • 💬 You commented 4 hours ago
   • 🟢 +127  🔴 -45  📄 4 files  ⏱️ ~10 min
   • 🔗 https://github.com/myorg/frontend-app/pull/42

↑ First line is bold with title, repo (no #PR), and author
  ↑ Space before number prevents markdown list parsing
    ↑ Summary appears first (omit line if empty)
      ↑ Metadata line with emoji-first natural phrasing (full words not abbreviations)
        ↑ Engagement line (omit if none)
          ↑ Diff stats with color emojis, second to last
            ↑ URL line with link emoji (terminal auto-colors blue)
```

**Dependabot PR** - Note the @dependabot author:

```
 8. **"Bump lodash from 4.17.20 to 4.17.21" • backend-api • @dependabot**
   • 📅 5 days old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +2  🔴 -2  📄 1 files  ⏱️ ~5 min
   • 🔗 https://github.com/myorg/backend-api/pull/156

↑ Dependabot PRs show @dependabot as author
  ↑ First line still bold
    ↑ No summary line (dependabot PRs typically have verbose auto-generated descriptions)
      ↑ Metadata line comes first after title
        ↑ Diff stats line, second to last
```

## Example Output Format

```
📋 PRs waiting for your review: 11 found | Est. total time: ~2h 15min (filtered out 3 from ignored-repo)

⚠️ ACTION REQUIRED (2):

 1. **"feat: add data validation layer" • data-pipeline • @bob**
   • 💬 Adds validation middleware for incoming data streams
   • 📅 1 year old • ✅ CI passing • 👀 Review required • ⚠️ Conflicts
   • ⚠️ Very old PR with conflicts - close or ask author to update
   • 🟢 +88  🔴 -335  📄 11 files  ⏱️ ~20 min
   • 🔗 https://github.com/myorg/data-pipeline/pull/47

 2. **"chore: update dependency management configuration" • backend-api • @charlie**
   • 💬 Migrates from legacy dependency manager to modern tooling
   • 📅 8 months old • ❌ CI failing • 👀 Review required • ✅ No conflicts
   • ⚠️ Failing CI for 8 months - needs immediate attention
   • 🟢 +45  🔴 -32  📄 5 files  ⏱️ ~5 min
   • 🔗 https://github.com/myorg/backend-api/pull/23

🎯 HIGH PRIORITY - Feature/Bug PRs (3):

 3. 🆕 **"Add user authentication" • frontend-app • @alice**
   • 💬 Implements JWT-based authentication for API endpoints
   • 📅 1 day old • ✅ CI passing • 👀 Review required • 👥 3 reviewers • ✅ No conflicts
   • 💬 You commented 4 hours ago
   • 🟢 +127  🔴 -45  📄 4 files  ⏱️ ~10 min
   • 🔗 https://github.com/myorg/frontend-app/pull/42

 4. **"Fix memory leak in cache layer" • data-service • @david**
   • 📅 4 days old • ✅ CI passing • ✅ Approved • 👥 2 reviewers • ✅ No conflicts
   • 🟢 +89  🔴 -12  📄 2 files  ⏱️ ~5 min
   • 🔗 https://github.com/myorg/data-service/pull/89

 5. **"Update navigation system" • mobile-app • @eve**
   • 💬 Refactors navigation to use latest routing library
   • 📅 2 days old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +234  🔴 -156  📄 8 files  ⏱️ ~20 min
   • 🔗 https://github.com/myorg/mobile-app/pull/156

🤖 DEPENDABOT - Dependency Updates (4):

 6. **"Bump lodash from 4.17.20 to 4.17.21" • frontend-app • @dependabot**
   • 📅 3 days old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +12  🔴 -8  📄 2 files  ⏱️ ~5 min
   • 🔗 https://github.com/myorg/frontend-app/pull/178

 7. **"Bump express from 4.18.0 to 4.18.2" • backend-api • @dependabot**
   • 📅 1 week old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +9  🔴 -9  📄 2 files  ⏱️ ~5 min
   • 🔗 https://github.com/myorg/backend-api/pull/201

[... more dependabot PRs ...]

🔧 CHORES - Infrastructure/Config (2):

 10. **"chore: update CI pipeline configuration" • infra-config • @frank**
    • 💬 Modernizes GitHub Actions workflows and adds caching
    • 📅 5 days old • ✅ CI passing • 👀 Review required • ✅ No conflicts
    • 🟢 +156  🔴 -89  📄 7 files  ⏱️ ~20 min
    • 🔗 https://github.com/myorg/infra-config/pull/34

 11. **"chore: refactor deployment scripts" • deployment-scripts • @grace**
    • 📅 1 week old • ✅ CI passing • 👀 Review required • ✅ No conflicts
    • 🟢 +67  🔴 -43  📄 3 files  ⏱️ ~10 min
    • 🔗 https://github.com/myorg/deployment-scripts/pull/12

Commands:
- Type a number (1-11) to review that PR (e.g., "3" to review frontend-app#42)
- After each review, I'll prompt: "Continue? (y/n/list/number)" to review more PRs

💡 Interactive workflow: Type a number → review PR → prompted for next → repeat until done
```

## Integration with Memory

This command works best when you've configured Memory with your preferences:

**Example Memory facts:**

- "When reviewing PRs: prioritize failing CI and stale PRs (>30 days old) first"

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
- Groups PRs by type: Feature/Bug → Dependabot → Chores
- Works seamlessly with the existing `/pr-review <number> --repo <org>/<repo>` command
- Cache file is always fresh - run `/review-queue` again if PR list has changed
- **Formatting trick**: PR numbers MUST start with a space (` 1.` not `1.`) to prevent markdown from treating them as ordered lists, which strips indentation from continuation lines. This preserves the 3-space indent before bullet points.

## Implementation Details

The `review-queue` skill (located at `~/.claude/skills/review-queue/`) handles all data fetching and processing:

**What the skill does:**

- Fetches PRs via GitHub GraphQL API
- Calculates ages, time estimates, CI/review/conflict status
- Counts unique reviewers and determines their latest review states
- Groups PRs by urgency (ACTION REQUIRED → Feature/Bug → Dependabot → Chores)
- Tracks viewing history (🆕 indicators)
- Saves cache files:
  - `~/.claude/.cache/review-queue.json` - PR lookup mapping (seq_num → repo#pr)
  - `~/.claude/.cache/review-queue-history.json` - Viewing history
- Returns structured JSON ready for formatting

**What the slash command does:**

- Invokes the skill
- Formats JSON output per the template
- Manages interactive session (y/n/list/number navigation)
- Launches `/pr-review` when user selects a PR

See `~/.claude/skills/review-queue/SKILL.md` for complete skill documentation.
