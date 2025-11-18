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
                        statuscheckrollup {
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
   - Present all PRs using the exact format template (see "Output Formatting" section)
   - Show available commands at the end

## Phase 2: Interactive Session

After displaying the PR list, enter an interactive loop. Do NOT exit after displaying - wait for user input and respond accordingly:

1. **Wait for user input** - The user can:
   - Type a number (e.g., "7") to review that specific PR
   - Type "list" to redisplay the PR queue

2. **When user types a number:**
   - Read the mapping from `~/.claude/.cache/review-queue.json`
   - Parse the repo and PR number
   - Launch `/pr-review <number> --repo <org>/<repo>`

3. **After each PR review completes:**
   - Update the cache with review completion timestamp
   - Calculate remaining PRs and next PR in sequence
   - Prompt: "Review complete. X remaining. Next: #Y. Continue? (y/n/list/number)"
     - "y" → Review next PR in sequence
     - "n" → Exit interactive session
     - "list" → Redisplay abbreviated PR list
     - number → Jump to specific PR by number

4. **Continue the loop** until user chooses to exit with "n"

## Output Formatting

Present all results using the exact template structure shown below. The template defines the required format, spacing, emojis, and field order for each PR entry. Do not improvise variations.

## Required Output Format Template

Use this exact template for each PR. Preserve spacing, emojis, and structure precisely:

```
{number}. {new_badge}{repo_short}#{pr_number} - "{title}" [+{additions} -{deletions}, {files} files] {time_estimate}
   By: @{author}
   Age: {age_str} | CI: {ci_status} | Review: {review_status} | {conflict_status}
   💬 {summary}
   {engagement_line}
   {urgency_line}
   {url}

```

**Field definitions:**

- `{new_badge}`: "🆕 " if PR not in history, otherwise empty string
- `{repo_short}`: Repository name without organization prefix
- `{time_estimate}`: "~5 min", "~10 min", "~20 min", "~30 min", or "~45 min"
- `{author}`: Author's GitHub username (omit "By:" line for dependabot PRs)
- `{ci_status}`: "✅ passing", "❌ failing", "⏸️ draft", or "⏳ pending"
- `{review_status}`: Format varies:
  - Simple: "✅ Approved", "🔍 Review required", "⚠️ Changes requested"
  - With reviews: "👥 {count} reviews (✅ {approved_count} approved, 💬 {commented_count} commented)"
    - Include emoji prefix (✅, ⚠️, 💬) before each count type
- `{conflict_status}`: "No conflicts ✅", "Conflicts ⚠️", or "Unknown"
- `{summary}`: First meaningful line from PR description (omit line if empty)
- `{engagement_line}`: Your engagement status (omit line if none):
  - " 💬 You commented {age} ago"
  - " ✅ You approved {age} ago"
  - " ⚠️ You requested changes {age} ago"
- `{urgency_line}`: Reason for urgency in ACTION REQUIRED section (omit elsewhere):
  - " ⚠️ {reason} - needs immediate attention"

## Annotated Format Examples

These examples highlight specific formatting requirements:

**Review status with multiple reviews** - Note the required emoji prefixes:

```
Review: 👥 3 reviews (✅ 1 approved, 💬  2 commented)
                      ^^              ^^
                    Required emoji prefixes for each count type
```

**Complete PR entry** - Note spacing and optional lines:

```
4. 🆕 frontend-app#42 - "Add user authentication" [+127 -45, 4 files] ~10 min
   By: @alice
   Age: 1d ago | CI: ✅ passing | Review: 🔍 Required | 👥 3 reviews (✅ 1 approved, 💬 2 commented) | No conflicts ✅
   💬 Implements JWT-based authentication for API endpoints
   💬 You commented 4h ago
   https://github.com/myorg/frontend-app/pull/42

↑ New badge (conditional)
  ↑ Summary line (omit if empty)
    ↑ Engagement line (omit if none)
      ↑ No urgency line (only in ACTION REQUIRED)
```

**Dependabot PR** - Note the omitted "By:" line:

```
8. backend-api#156 - "Bump lodash from 4.17.20 to 4.17.21" [+2 -2, 1 files] ~5 min
   Age: 5d ago | CI: ✅ passing | Review: 🔍 Required | No conflicts ✅
   https://github.com/myorg/backend-api/pull/156

↑ No "By:" line for dependabot
  ↑ No summary line (dependabot PRs typically have verbose auto-generated descriptions)
```

## Example Output Format

```
📋 PRs waiting for your review: 11 found | Est. total time: ~2h 15min (filtered out 3 from ignored-repo)

⚠️ ACTION REQUIRED (2):

1. data-pipeline#47 - "feat: add data validation layer" [+88 -335, 11 files] ~20 min
   By: @bob
   Age: 1y ago | CI: ✅ passing | Review: 🔍 Review required | Conflicts ⚠️
   💬 Adds validation middleware for incoming data streams
   ⚠️ Very old PR with conflicts - close or ask author to update
   https://github.com/myorg/data-pipeline/pull/47

2. backend-api#23 - "chore: update dependency management configuration" [+45 -32, 5 files] ~5 min
   By: @charlie
   Age: 8mo ago | CI: ❌ failing | Review: 🔍 Review required | No conflicts ✅
   💬 Migrates from legacy dependency manager to modern tooling
   ⚠️ Failing CI for 8 months - needs immediate attention
   https://github.com/myorg/backend-api/pull/23

🎯 HIGH PRIORITY - Feature/Bug PRs (3):

3. 🆕 frontend-app#42 - "Add user authentication" [+127 -45, 4 files] ~10 min
   By: @alice
   Age: 1d ago | CI: ✅ passing | Review: 🔍 Required | 👥 3 reviews (✅ 1 approved, 💬 2 commented) | No conflicts ✅
   💬 Implements JWT-based authentication for API endpoints
   💬 You commented 4h ago
   https://github.com/myorg/frontend-app/pull/42

4. data-service#89 - "Fix memory leak in cache layer" [+89 -12, 2 files] ~5 min
   By: @david
   Age: 4d ago | CI: ✅ passing | Review: ✅ Approved | 👥 2 reviews (✅ 2 approved) | No conflicts ✅
   https://github.com/myorg/data-service/pull/89

5. mobile-app#156 - "Update navigation system" [+234 -156, 8 files] ~20 min
   By: @eve
   Age: 2d ago | CI: ✅ passing | Review: 🔍 Review required | No conflicts ✅
   💬 Refactors navigation to use latest routing library
   https://github.com/myorg/mobile-app/pull/156

🤖 DEPENDABOT - Dependency Updates (4):

6. frontend-app#178 - "Bump lodash from 4.17.20 to 4.17.21" [+12 -8, 2 files] ~5 min
   Age: 3d ago | CI: ✅ passing | Review: 🔍 Required | No conflicts ✅
   https://github.com/myorg/frontend-app/pull/178

7. backend-api#201 - "Bump express from 4.18.0 to 4.18.2" [+9 -9, 2 files] ~5 min
   Age: 1w ago | CI: ✅ passing | Review: 🔍 Required | No conflicts ✅
   https://github.com/myorg/backend-api/pull/201

[... more dependabot PRs ...]

🔧 CHORES - Infrastructure/Config (2):

10. infra-config#34 - "chore: update CI pipeline configuration" [+156 -89, 7 files] ~20 min
    By: @frank
    Age: 5d ago | CI: ✅ passing | Review: 🔍 Review required | No conflicts ✅
    💬 Modernizes GitHub Actions workflows and adds caching
    https://github.com/myorg/infra-config/pull/34

11. deployment-scripts#12 - "chore: refactor deployment scripts" [+67 -43, 3 files] ~10 min
    By: @grace
    Age: 1w ago | CI: ✅ passing | Review: 🔍 Review required | No conflicts ✅
    https://github.com/myorg/deployment-scripts/pull/12

Commands:
- Type a number (1-11) to review that PR (e.g., "3" to review frontend-app#42)
- Type 'approve-all-deps' to approve all 4 passing dependabot PRs
- After each review, I'll prompt: "Continue? (y/n/list/number)" to review more PRs

💡 Interactive workflow: Type a number → review PR → prompted for next → repeat until done
```

## Integration with Memory

This command works best when you've configured Memory with your preferences:

**Example Memory facts:**

- "When reviewing PRs: prioritize failing CI and stale PRs (>30 days old) first"
- "Dependabot PRs: batch-approve if CI passes and version bumps are minor/patch only"

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

## Implementation Details

The command uses a Python script to:

1. Fetch PRs via GitHub GraphQL API (with additions, deletions, changedFiles, mergeable, reviewDecision, reviews, bodyText)
2. Calculate human-readable ages from ISO timestamps
3. Calculate review time estimates based on total lines changed for each PR
4. Calculate total estimated review time across all PRs
5. Parse CI status from statusCheckRollup
6. Parse review status from reviewDecision and individual reviews:
   - Overall status (APPROVED, REVIEW_REQUIRED, CHANGES_REQUESTED)
   - Individual reviewer actions (who approved, requested changes, commented)
   - Review engagement summary (e.g., "3 reviews: 1 approved, 2 commented")
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
16. Update history file with current timestamp for all displayed PRs
17. Display available commands and explain interactive workflow
18. When user types a number:
    - Read mapping from cache file
    - Parse repo and PR number
    - Launch `/pr-review <number> --repo <org>/<repo>`
    - After review completes, update cache with last_reviewed
    - Prompt for next action (y/n/list/number)
