# Review Queue - Find PRs waiting for my review

Fetch all open PRs where I'm requested as a reviewer across ALL recursionpharma repos, filter by repos I care about, and present them in priority order.

## Steps

1. **Fetch PRs using GraphQL API:**

   The `gh search prs` command doesn't work with private repos, so use GraphQL instead:

   ```bash
   gh api graphql -f query='
   query {
     search(query: "is:pr is:open archived:false user:recursionpharma review-requested:ooloth sort:created-desc", type: ISSUE, first: 50) {
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
   }'
   ```

2. **Filter to repos I care about:**

   IGNORE these repos (don't show PRs from here):
   - recursionpharma/build-pipelines
   - demo-repos
   - archived-*
   - legacy-*

   Check Memory for additional repo preferences.

3. **Group and prioritize PRs:**

   Group PRs into categories:
   - **HIGH PRIORITY** - Feature/Bug PRs (not chores, not dependabot)
   - **DEPENDABOT** - Automated dependency updates
   - **CHORES** - Infrastructure/config changes (title starts with "chore:")

   Within each group, sort by:
   - Failing CI first
   - Then by age (oldest first for stale reviews)

4. **Calculate review time estimates:**

   Based on total lines changed (additions + deletions):
   - 0-50 lines: ~5 min
   - 51-200 lines: ~10 min
   - 201-500 lines: ~20 min
   - 501-1000 lines: ~30 min
   - 1000+ lines: ~45 min

5. **Present results with key details:**

   For each PR show:
   - Repo name (without "recursionpharma/" prefix)
   - PR number and title
   - **Size and time estimate** (e.g., "[+127 -45, 4 files] ~10 min")
   - Author login
   - Age (human-readable: "2d ago", "3mo ago", "1y ago")
   - CI status: ✅ passing, ❌ failing, ⏸️ draft, ⏳ pending
   - Link

6. **Offer next actions:**

   Ask user which PR they want to review, then:
   - Use the existing `/pr-review <number> --repo recursionpharma/<repo>` for full analysis
   - OR offer to batch-approve multiple dependabot PRs if appropriate

## Example Output Format

```
📋 PRs waiting for your review: 11 found (filtered out 8 from build-pipelines)

🎯 HIGH PRIORITY - Feature/Bug PRs (3):

1. cell-sight#39 - "Add cell neighborhood table" [+127 -45, 4 files] ~10 min
   By: @marianna-trapotsi-rxrx
   Age: 1d ago | Status: ✅ passing
   https://github.com/recursionpharma/cell-sight/pull/39

2. spade-flows#144 - "Use prototype trekseq" [+89 -12, 2 files] ~5 min
   By: @isaacks123
   Age: 4d ago | Status: ✅ passing
   https://github.com/recursionpharma/spade-flows/pull/144

3. rp006-brnaseq-analysis-flow#2 - "Introduce Docker-less dev environment" [+2,340 -890, 23 files] ~45 min
   By: @jackdhaynes
   Age: 5mo ago | Status: ⏸️ draft
   https://github.com/recursionpharma/rp006-brnaseq-analysis-flow/pull/2

🤖 DEPENDABOT - Dependency Updates (7):

1. dash-phenoapp-v2#1839 - "Bump the npm_and_yarn group across 1 directory with 2 updates" [+12 -8, 2 files] ~5 min
   Age: 3d ago | Status: ✅ passing
   https://github.com/recursionpharma/dash-phenoapp-v2/pull/1839

[... more dependabot PRs ...]

🔧 CHORES - Infrastructure/Config (1):

1. phenomics-potency-prediction#2 - "chore: switch sourcing Python packages from Nexus to GAR" [+45 -32, 5 files] ~5 min
   By: @dmaljovec
   Age: 8mo ago | Status: ❌ failing
   https://github.com/recursionpharma/phenomics-potency-prediction/pull/2

Which PR would you like to review?
```

## Integration with Memory

This command works best when you've configured Memory with your preferences:

**Example Memory facts:**
- "For PR reviews at recursionpharma: I ignore PRs from recursionpharma/build-pipelines (always filtered out)"
- "When reviewing PRs: prioritize failing CI and stale PRs (>30 days old) first"
- "Dependabot PRs: batch-approve if CI passes and version bumps are minor/patch only"

## Notes

- This command is **global** - run it from any directory
- It searches across **all recursionpharma repos**
- **Automatically filters out** recursionpharma/build-pipelines PRs
- Uses GraphQL API for private repo access (not `gh search prs`)
- Groups PRs by type: Feature/Bug → Dependabot → Chores
- Works seamlessly with the existing `/pr-review <number> --repo <org>/<repo>` command
- Can be extended to check for merge conflicts, stale branches, etc.

## Implementation Details

The command uses a Python script to:
1. Fetch PRs via GitHub GraphQL API (with additions, deletions, changedFiles)
2. Calculate human-readable ages from ISO timestamps
3. Calculate review time estimates based on total lines changed
4. Parse CI status from statusCheckRollup
5. Filter out build-pipelines repo
6. Group by author (dependabot) and title prefix (chore:)
7. Format output with size info, time estimates, emojis, and status indicators
