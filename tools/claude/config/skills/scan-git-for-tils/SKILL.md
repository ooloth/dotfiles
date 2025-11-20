---
name: scan-git-for-tils
description: Scans GitHub commit history for commits that might make good TIL blog posts. Queries all your repos across all orgs via GitHub API. Tracks assessed commits in Notion to avoid duplicates across machines. Use when user asks for TIL ideas from their recent work.
allowed-tools: [Bash]
---

# Scan Git for TILs Skill

Analyzes recent GitHub commits across all your repos to find TIL-worthy topics.

## Notion Database

**TIL Assessed Commits Database**
- Database ID: `928fcd9e47a84f98824790ac5a6d37ca`
- Data Source ID: `cba80148-aeef-49c9-ba45-5157668b17b3`

Properties:
- `Commit Hash` (title): Full SHA hash
- `Message`: Commit message
- `Repo`: Repository full name
- `Commit Date` (date): When the commit was made
- `Writing` (relation): Link to Writing database if TIL was drafted
- `Assessed` (date): When commit was assessed

## Usage

### Step 1: Fetch assessed hashes from Notion

Use `mcp__notion__notion-search` to get existing hashes:

```
Search the "TIL Assessed Commits" database to get all commit hashes
```

Extract the "Commit Hash" property from all pages.

### Step 2: Run the script

```bash
python3 ~/.claude/skills/scan-git-for-tils/scan_git.py [days] --assessed-hashes hash1,hash2,...
```

**Arguments:**
- `days` (optional): Number of days to look back (default: 30)
- `--assessed-hashes`: Comma-separated list of full commit hashes from Notion

**Output:** JSON with:
- `markdown`: Formatted suggestions to display
- `new_commits`: Array of commits to add to Notion

### Step 3: Evaluate commits

Review the commits in the `markdown` field and identify the top 5-10 that would make good TILs.

**Good TIL candidates have:**
- Solved a non-obvious problem (gotchas, edge cases, surprising behavior)
- Learned something worth sharing (new technique, tool usage, configuration)
- Fixed a bug that others might encounter
- Set up tooling or configuration that was tricky
- Implemented a pattern that could help others

**Skip commits that are:**
- Routine maintenance (version bumps, dependency updates, cleanup)
- Trivial changes (typos, formatting, simple renames)
- Chores without learning value (CI tweaks, file reorganization)
- Too project-specific to be useful to others

For each selected commit, generate:
- **Suggested title**: Clear, direct (e.g., "How to X" or "Why Y happens")
- **TIL angle**: The specific learning worth documenting

### Step 4: Display results

Present your evaluation to the user:

```
📝 TIL Opportunities from Git History (last N days):

1. **Suggested Title Here**
   - Repo: owner/repo
   - Commit: abc1234 "original commit message"
   - Date: 3 days ago
   - Files: file1.py, file2.py
   - TIL angle: What makes this worth documenting
   - URL: https://github.com/...

2. ...
```

### Step 5: Write new commits to Notion

For each item in `new_commits`, create a page in the TIL Assessed Commits database:

```json
{
  "parent": {
    "data_source_id": "cba80148-aeef-49c9-ba45-5157668b17b3"
  },
  "pages": [{
    "properties": {
      "Commit Hash": "<hash>",
      "Message": "<message>",
      "Repo": "<repo>",
      "date:Commit Date:start": "<commit date ISO>",
      "date:Commit Date:is_datetime": 0,
      "date:Assessed:start": "<today's date ISO>",
      "date:Assessed:is_datetime": 0
    }
  }]
}
```

## What It Returns

JSON output example:

```json
{
  "markdown": "Git commits from last 30 days:\n\n1. [ooloth/dotfiles] fix: properly ignore .env\n   Hash: abc1234 | Date: 3 days ago\n   ...",
  "new_commits": [
    {
      "hash": "abc1234567890...",
      "message": "fix: properly ignore .env after initial commit",
      "repo": "ooloth/dotfiles",
      "date": "2025-01-15"
    },
    ...
  ]
}
```

## How It Works

1. **Script fetches commits** - Queries GitHub API for your recent commits across all repos
2. **Filters obvious skips** - Removes merge commits, dependabot, already-assessed
3. **Returns all candidates** - Outputs commit details for Claude to evaluate
4. **Claude evaluates** - Reviews commits and selects top TIL candidates
5. **Records to Notion** - Marks all fetched commits as assessed

## Notes

- Requires `gh` CLI installed and authenticated
- Queries commits across all repos you have access to (personal + orgs)
- Script filters merge commits and dependency bot commits
- Claude evaluates remaining commits for TIL potential
- Notion sync prevents duplicate suggestions across machines
