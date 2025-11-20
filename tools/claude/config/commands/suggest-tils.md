# Suggest TILs - Find and draft TIL blog posts

Scan for TIL opportunities from git history and Notion backlog, then draft selected topics.

## Phase 1: Source Selection

Ask the user which sources to scan:

```
📝 TIL Suggestion Sources

Which sources should I scan?
1. Git history
2. Notion backlog (unpublished blog items)
3. Both

>
```

If user selects git history (1 or 3), ask about date range:

```
How far back should I search?
- Enter number of days (default: 30)
- Or 'all' for maximum history

>
```

Note: GitHub API returns max ~1000 commits, so very large ranges may be truncated.

## Phase 2: Scan Sources

Based on selection, invoke the appropriate skills.

### For Git History

Use the `scan-git-for-tils` skill:

1. Fetch assessed commit hashes from "TIL Assessed Commits" database
2. Run the scan script with those hashes
3. Display the markdown results
4. Write new commits to Notion database

### For Notion Backlog

Use the `scan-notion-for-tils` skill:

1. Search Writing database for blog-destined, unpublished items
2. Filter out items with Claude Draft already linked
3. Categorize as "ready to draft" or "needs development"
4. Display formatted suggestions

### For Both

Run both scans sequentially, then combine results.

## Phase 3: Selection

After displaying results:

```
Select a topic to work on (number), or:
- 'g' to scan git again with more days
- 'n' to scan notion again
- 'q' to quit

>
```

## Phase 4: Draft or Develop

When user selects a topic:

### If from Git (or ready Notion item)

Use the `draft-til` skill:

1. Show user the proposed TIL content before creating
2. Ask for approval or edits
3. Create the page in Writing database with Status = "Claude Draft"
4. For Notion sources: link draft to source item via Writing relation
5. For Git sources: update TIL Assessed Commits with Writing relation

### If Notion item needs development

1. Fetch the source item's full content
2. Research the topic (web search, codebase exploration)
3. Draft developed content in a new Writing page
4. Link to source item
5. Show user for review

## Phase 5: Post-Creation

After creating a draft:

```
✅ Draft created in Writing database

Title: "Your TIL Title"
Status: Claude Draft
URL: https://www.notion.so/...

Actions:
o - Open in Notion
d - Draft another from suggestions
n - New scan
q - Done

>
```

## State Management

Use TodoWrite to track workflow state:

```
- "Scanning git history for TILs" (in_progress)
- "Scanning Notion backlog for TILs" (pending)
- "Waiting for user selection" (pending)
- "Drafting TIL" (pending)
```

Update todos as you progress through phases.

## Safety Rules

1. **Never edit existing Writing items** - only create new Claude Draft pages
2. **Show content before creating** - user approves draft text first
3. **Always use Status = "Claude Draft"** - never other statuses
4. **Link sources properly** - git commits and Notion items get linked to drafts

## Notes

- This command orchestrates the three TIL skills (scan-git, scan-notion, draft-til)
- User can iterate: draft one, return to suggestions, draft another
- Git scanning updates the TIL Assessed Commits database
- Notion scanning uses Writing relations as the "assessed" indicator
- All drafts go into the Writing database for user review and publishing
