# Review Queue - Find PRs waiting for my review

Fetch all open PRs where I'm requested as a reviewer across all relevant recursionpharma repos and present them in priority order to be reviewed.

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

## Your task

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

3. **Present results with key details:**

   For each PR show:
   - Repo name (without "recursionpharma/" prefix)
   - PR number and title
   - **Size and time estimate** (e.g., "[+127 -45, 4 files] ~10 min")
   - Author login
   - Age (human-readable: "2d ago", "3mo ago", "1y ago")
   - **Review status** (e.g., "✅ Approved", "🔍 Review required", "⚠️ Changes requested")
   - **Conflict status** (e.g., "No conflicts ✅", "Conflicts ⚠️", "Unknown")
   - CI status: ✅ passing, ❌ failing, ⏸️ draft, ⏳ pending
   - **Brief summary** (first line or sentence from PR description, if available)
   - Link

4. **Number PRs consecutively:**

   Assign sequential numbers (1, 2, 3...) across all PRs in all sections for easy reference.
   Store the mapping of number → (repo, PR number) for quick lookup.

5. **Store PR mapping for interactive use:**

   Save the PR number mapping to `~/.cache/claude-review-queue.json` for quick lookup when user types a number.

6. **Offer next actions:**

   Show available commands:
   - Type a number (e.g., "7") to review that specific PR → launches `/pr-review`
   - After each review, prompt: "Review complete. X remaining. Next: #Y. Continue? (y/n/list/number)"
     - "y" → Review next PR in sequence
     - "n" → Exit
     - "list" → Show abbreviated PR list again
     - number → Jump to specific PR
   - Type "approve-all-deps" to batch-approve all passing dependabot PRs

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
- `{repo_short}`: Repository name without "recursionpharma/" prefix
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
  - "   💬 You commented {age} ago"
  - "   ✅ You approved {age} ago"
  - "   ⚠️ You requested changes {age} ago"
- `{urgency_line}`: Reason for urgency in ACTION REQUIRED section (omit elsewhere):
  - "   ⚠️ {reason} - needs immediate attention"

## Example Output Format

```

📋 PRs waiting for your review: 13 found | Est. total time: ~2h 30min (filtered out 7 from build-pipelines)

⚠️ ACTION REQUIRED (3):

1. perturbseq-map#94 - "feat: a first pass script to prepare an scVI embedding for mapapp perusal" [+88 -335, 11 files] ~20 min
   By: @dmaljovec
   Age: 1y ago | CI: ✅ passing | Review: 🔍 Review required | Conflicts ⚠️
   💬 Adds preprocessing script to generate scVI embeddings for visualization in mapapp
   ⚠️ Very old PR with conflicts - close or ask author to update
   https://github.com/recursionpharma/perturbseq-map/pull/94

2. phenomics-potency-prediction#2 - "chore: switch sourcing Python packages from Nexus to GAR" [+45 -32, 5 files] ~5 min
   By: @dmaljovec
   Age: 8mo ago | CI: ❌ failing | Review: 🔍 Review required | No conflicts ✅
   💬 Updates Python package repository from Nexus to Google Artifact Registry
   ⚠️ Failing CI for 8 months - needs immediate attention
   https://github.com/recursionpharma/phenomics-potency-prediction/pull/2

3. dash-phenoapp-v2#1498 - "Bump react-toastify from 7.0.4 to 11.0.5 in /react-app" [+9 -16, 2 files] ~5 min
   Age: 8mo ago | CI: ✅ passing | Review: 🔍 Review required | Conflicts ⚠️
   ⚠️ Old dependabot PR with conflicts - likely stale, consider closing
   https://github.com/recursionpharma/dash-phenoapp-v2/pull/1498

🎯 HIGH PRIORITY - Feature/Bug PRs (2):

4. 🆕 cell-sight#39 - "Add cell neighborhood table" [+127 -45, 4 files] ~10 min
   By: @marianna-trapotsi-rxrx
   Age: 1d ago | CI: ✅ passing | Review: 🔍 Required | 👥 3 reviews (✅ 1 approved, 💬 2 commented) | No conflicts ✅
   💬 You commented 4h ago
   https://github.com/recursionpharma/cell-sight/pull/39

5. spade-flows#144 - "Use prototype trekseq" [+89 -12, 2 files] ~5 min
   By: @isaacks123
   Age: 4d ago | CI: ✅ passing | Review: ✅ Approved | 👥 2 reviews (✅ 2 approved) | No conflicts ✅
   https://github.com/recursionpharma/spade-flows/pull/144

🤖 DEPENDABOT - Dependency Updates (5):

5. dash-phenoapp-v2#1839 - "Bump the npm_and_yarn group across 1 directory with 2 updates" [+12 -8, 2 files] ~5 min
   Age: 3d ago | CI: ✅ passing | Review: 🔍 Required | No conflicts ✅
   https://github.com/recursionpharma/dash-phenoapp-v2/pull/1839

6. dash-phenoapp-v2#1821 - "Bump @types/node from 22.17.2 to 24.9.2" [+9 -9, 2 files] ~5 min
   Age: 20d ago | CI: ✅ passing | Review: 🔍 Required | No conflicts ✅
   https://github.com/recursionpharma/dash-phenoapp-v2/pull/1821

[... more dependabot PRs ...]

Commands:

- Type a number (1-11) to review that PR (e.g., "7" to review cell-sight#39)
- Type 'approve-all-deps' to approve all 5 passing dependabot PRs
- After each review, I'll prompt: "Continue? (y/n/list/number)" to review more PRs

💡 Interactive workflow: Type a number → review PR → prompted for next → repeat until done

```

## Integration with Memory

This command works best when you've configured Memory with your preferences:

**Example Memory facts:**

- "For PR reviews at recursionpharma: I ignore PRs from recursionpharma/build-pipelines (always filtered out)"
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
- It searches across **all recursionpharma repos**
- **Automatically filters out** recursionpharma/build-pipelines PRs
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
9. Filter out build-pipelines repo
10. Identify "Action Required" PRs (failing CI, >6mo old, or >3mo old with conflicts)
11. Group by urgency: Action Required → Feature/Bug → Dependabot → Chores
12. Assign consecutive numbers (1-N) across all PRs for easy reference
13. Track PR viewing history in ~/.claude/.cache/review-queue-history.json:
    - **Updated (not overwritten)** - Persists your interaction history
    - Records when you first saw each PR and your engagement
    - Used to show "🆕 New" indicator for unseen PRs

    ```json
    {
      "recursionpharma/cell-sight#39": {
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
      "1": "recursionpharma/rp006-brnaseq-analysis-flow#2",
      "2": "recursionpharma/template-javascript-react#63",
      ...
      "total": 12,
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
