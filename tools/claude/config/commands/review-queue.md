# Review Queue - Find PRs waiting for my review

Fetch all open PRs where I'm requested as a reviewer across all relevant repos and present them in priority order to be reviewed.

## Context

- My PR review requests: !`gh api graphql -f query='query {
   search(query: "is:pr is:open archived:false user:recursionpharma review-requested:ooloth -repo:recursionpharma/build-pipelines sort:created-desc", type: ISSUE, first: 50) {
      issueCount
      edges {
         node {
            ... on PullRequest {
               number
               title
               url
               createdAt
               isDraft
               additions
               deletions
               changedFiles
               mergeable
               reviewDecision
               bodyText
               comments(last: 20) {
                  totalCount
                  nodes {
                     author {
                        login
                     }
                     createdAt
                  }
               }
               reviews(last: 20) {
                  totalCount
                  nodes {
                     state
                     author {
                        login
                     }
                     submittedAt
                  }
               }
               repository {
                  nameWithOwner
               }
               author {
                  login
               }
               commits(last: 1) {
                  nodes {
                     commit {
                        statusCheckRollup {
                           state
                        }
                     }
                  }
               }
            }
         }
      }
   }
}'`

## Phase 1: Display PRs

Based on the above output, process and display all PRs waiting for review:

1. **Group and prioritize PRs:**

   Group PRs into categories:
   - **ACTION REQUIRED** - Urgent items (failing CI, very old >6mo, conflicts on old PRs)
   - **HIGH PRIORITY** - Feature/Bug PRs (not chores, not dependabot)
   - **DEPENDABOT** - Automated dependency updates
   - **CHORES** - Infrastructure/config changes (title starts with "chore:")

   Within each group, sort by:
   - Failing CI first
   - Then by age (oldest first for stale reviews)

2. **Calculate review time estimates:**

   Based on total lines changed (additions + deletions):
   - 0-50 lines: ~5 min
   - 51-200 lines: ~10 min
   - 201-500 lines: ~20 min
   - 501-1000 lines: ~30 min
   - 1000+ lines: ~45 min

   Also calculate total estimated time across all PRs for planning purposes.

3. **Extract data for each PR:**

   For each PR, extract:
   - Repo name, PR number, title, URL
   - Author login
   - Size metrics (additions, deletions, changed files)
   - Age (calculate from createdAt)
   - Review status (from reviewDecision and reviews)
   - Conflict status (from mergeable)
   - CI status (from statusCheckRollup)
   - Brief summary (first meaningful line from bodyText)
   - Your engagement (check if ooloth has commented or reviewed)

4. **Number PRs and store mapping:**
   - Assign sequential numbers (1, 2, 3...) across all PRs in all sections for easy reference
   - Save the PR number mapping to `~/.claude/.cache/review-queue.json` for quick lookup
   - Track viewing history in `~/.claude/.cache/review-queue-history.json` to show "🆕" indicators

5. **Display formatted results:**
   - Run the Python script via Bash to process PRs and save cache files
   - **IMPORTANT**: Display the script output inline in your text response (not just in tool output)
   - The formatted output should be your complete message - no additional commentary
   - Present all PRs using the exact format template (see "Output Formatting" section)
   - Show available commands at the end

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
  - Breakdown shows each reviewer's most recent review state (e.g., "👥 3 reviewers (✅ 1 approved, 💬  2 commented)")
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

The command uses a Python script to:

1. Fetch PRs via GitHub GraphQL API (with additions, deletions, changedFiles, mergeable, reviewDecision, reviews, bodyText)
2. Calculate human-readable ages from ISO timestamps
3. Calculate review time estimates based on total lines changed for each PR
4. Calculate total estimated review time across all PRs
5. Parse CI status from statusCheckRollup
6. Parse review status from reviewDecision and individual reviews:
   - Overall status (APPROVED, REVIEW_REQUIRED, CHANGES_REQUESTED)
   - Count unique human reviewers (excluding bots like copilot-pull-request-reviewer)
   - For each reviewer, determine their most recent review state (approved, changes requested, or commented)
   - Review engagement summary shows unique reviewers and their latest states (e.g., "👥 3 reviewers (✅ 1 approved, 💬 2 commented)")
   - **Your engagement**: Check if you (ooloth) have commented or reviewed
     - Show "💬 You commented 2d ago" or "✅ You approved 3d ago" with most recent timestamp
7. Parse conflict status from mergeable (MERGEABLE → "No conflicts ✅", CONFLICTING → "Conflicts ⚠️", UNKNOWN → "Unknown")
8. Extract brief summary from bodyText (first line/sentence, max ~100 chars)
9. Filter out ignored repos as specified in query
10. Identify "Action Required" PRs (failing CI, >6mo old, or >3mo old with conflicts)
11. Group by urgency: Action Required → Feature/Bug → Dependabot → Chores
12. Assign consecutive numbers (1-N) across all PRs for easy reference
13. Track PR viewing history in ~/.claude/.cache/review-queue-history.json:
    - **Updated (not overwritten)** - Persists your interaction history
    - Records when you first saw each PR and your engagement
    - Used to show "🆕 New" indicator for unseen PRs

    ```json
    {
      "myorg/frontend-app#42": {
        "first_seen": "2025-11-18T10:00:00Z",
        "last_seen": "2025-11-18T12:00:00Z"
      }
    }
    ```

14. Store PR lookup mapping in ~/.claude/.cache/review-queue.json:
    - **Overwritten on each run** - Always has fresh PR data (list changes over time)
    - Used when user types a number to lookup which PR to review
    ```json
    {
      "1": "myorg/data-pipeline#47",
      "2": "myorg/backend-api#23",
      ...
      "total": 11,
      "generated_at": "2025-11-18T17:00:49Z"
    }
    ```
15. Format output with total time, size info, time estimates, review status, conflict status, summaries, urgency reasons, emojis, and status indicators
    - **🆕 indicator** for PRs not in history (never seen before)
    - **Your engagement**: "💬 You commented 2d ago" if you have comments/reviews
    - **Diff stats**: Color-coded with 🟢 for additions, 🔴 for deletions, 📄 for files, ⏱️ for time estimate
    - **Line order**: Summary (if present), metadata, engagement (if present), urgency (if present), diff stats, URL
16. Update history file with current timestamp for all displayed PRs
17. Display available commands and explain interactive workflow
18. When user types a number:
    - Read mapping from cache file
    - Parse repo and PR number
    - Launch `/pr-review <number> --repo <org>/<repo>`
    - After review completes, update cache with last_reviewed
    - Prompt for next action (y/n/list/number)
