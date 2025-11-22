---
name: scanning-git-for-tils
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

### Step 1: Run the script

```bash
python3 ~/.claude/skills/scanning-git-for-tils/scan_git.py [days]
```

**Arguments:**
- `days` (optional): Number of days to look back (default: 30)

The script automatically:
- Fetches assessed commit hashes from Notion (via 1Password for auth)
- Fetches your commits from GitHub
- Filters out already-assessed commits

**Output:** JSON with:
- `markdown`: Commit details for Claude to evaluate
- `new_commits`: Array of commits with hash, message, repo, date

### Step 2: Evaluate commits

Review the commits in the `markdown` field and identify the top 5-10 that would make good TILs.

**Important**: The markdown shows commits with an `(index: N)` - this maps to `new_commits[N]` array which contains full commit data you'll need for publishing.

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

For each selected commit:
1. Note the index number from markdown
2. Look up full commit data in `new_commits[index]`
3. Generate:
   - **Suggested title**: Clear, direct (e.g., "How to X" or "Why Y happens")
   - **TIL angle**: The specific learning worth documenting

### Step 3: Display results

Present suggestions **ranked from best to worst by TIL potential**:

```
📝 TIL Opportunities from Git History (last N days):

1. **Suggested Title Here** [BEST]
   - Repo: owner/repo
   - Commit: abc1234 "original commit message"
   - Date: 3 days ago
   - Files: file1.py, file2.py
   - TIL angle: What makes this worth documenting
   - URL: https://github.com/...

2. **Second Best Title**
   ...

10. **Still Worth Documenting**
   ...
```

**Ranking criteria (highest priority first):**
1. **Broad applicability** - Will help many developers, not project-specific
2. **Non-obvious insight** - Gotcha, surprising behavior, or clever solution
3. **Recency** - More recent commits are fresher to write about
4. **Clear learning** - Easy to extract a concrete takeaway

**Note**: Don't create tracker entries at this stage. The `publish_til.py` script will create tracker entries when drafts are actually published. This prevents duplicates and ensures only drafted commits are marked as assessed.

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
4. **Claude evaluates** - Reviews commits and selects top 5-10 TIL candidates
5. **Records suggestions to Notion** - Only suggested commits are marked as assessed (allows incremental backlog review)

## Notes

- Requires `gh` CLI installed and authenticated
- Requires `op` CLI installed and authenticated (1Password)
- Notion token stored at `op://Scripts/Notion/api-access-token`
- Searches commits authored by your GitHub username (includes any repos where you've committed)
- Script filters merge commits and dependency bot commits
- Claude evaluates remaining commits for TIL potential
- Notion sync prevents duplicate suggestions across machines
