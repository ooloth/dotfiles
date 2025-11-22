# Suggest TILs - Find and draft TIL blog posts

Scan git history for TIL opportunities, then draft selected topics.

## Phase 1: Date Range Selection

Ask the user how far back to search:

```
📝 TIL Suggestions from Git History

How far back should I search?
- Enter number of days (default: 30)
- Or just press Enter for 30 days

>
```

Note: Very large ranges (365+ days) may take longer but will find more candidates.

## Phase 2: Scan Git History

Use the `scanning-git-for-tils` skill:

1. Run the scan script with the specified days
2. Script automatically fetches assessed commits from Notion
3. Script fetches and filters GitHub commits
4. Display the markdown results for evaluation

## Phase 3: Selection

After displaying results:

```
Select a commit to draft (enter number), or:
- 's' to scan again with different date range
- 'q' to quit

>
```

## Phase 4: Draft TIL

When user selects a commit:

Use the `drafting-til` skill:

1. Look up full commit data using the index from `new_commits` array
2. Generate TIL content following voice guide
3. Show draft to user for approval
4. When approved, pass JSON to `publish_til.py` script
5. Display Writing page URL from script output

## Phase 5: Post-Creation

After successfully publishing a draft:

```
✅ Draft published to Writing database

Title: "Your TIL Title"
Status: Claude Draft
URL: https://www.notion.so/...

Actions:
- Select another commit number to draft
- 's' to scan again with different date range
- 'q' to finish

>
```

## State Management

Use TodoWrite to track workflow state:

```
- "Scanning git history for TILs" (in_progress)
- "Waiting for user selection" (pending)
- "Drafting TIL" (pending)
- "Publishing draft" (pending)
```

Update todos as you progress through phases.

## Safety Rules

1. **Show content before publishing** - user must approve draft text
2. **Use `publish_til.py` for all Notion operations** - don't create pages manually
3. **Reference commits by index** - use `new_commits[index]` for full data
4. **Let script handle duplicates** - it checks for existing tracker entries

## Notes

- This command orchestrates the git scanning and drafting workflow
- User can draft multiple TILs from one scan
- Only drafted commits get marked as assessed (others stay in pool for next scan)
- All drafts go into Writing database with Status="Claude Draft"
- Tracker entries link back to drafts via Writing relation
