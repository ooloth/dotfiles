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

### Step 3: Display results

Show the `markdown` field to the user.

### Step 4: Write new commits to Notion

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
  "markdown": "📝 TIL Opportunities from Git History (last 30 days):\n\n1. **Git: Ignoring already-tracked files**\n   - Repo: ooloth/dotfiles\n   - Commit: abc1234 \"fix: properly ignore .env\"\n   ...",
  "new_commits": [
    {
      "hash": "abc1234567890...",
      "message": "fix: properly ignore .env after initial commit",
      "repo": "ooloth/dotfiles"
    },
    ...
  ]
}
```

## What to Look For

The script identifies commits with these patterns:

1. **Bug fixes** - Commits with "fix" that solved a non-obvious problem
2. **Configuration changes** - Dotfiles, CI, tooling setup
3. **Dependency updates** - Updates that required code changes
4. **Detailed messages** - Commits explaining "why" not just "what"
5. **Repeated patterns** - Same problem solved multiple times

## Processing Done by Skill

1. Queries GitHub API for your recent commits across all repos
2. Filters out previously assessed commits (passed via --assessed-hashes)
3. Scores commits based on TIL potential:
   - Has "fix", "resolve", "workaround" in message
   - Touches config files (.rc, .config, .json, .yaml)
   - Has detailed commit message (multiple lines or >100 chars)
   - Related to common gotcha patterns
4. Generates TIL angle suggestions based on commit content
5. Returns JSON with markdown display and new commits to record

## Notes

- Requires `gh` CLI installed and authenticated
- Queries commits across all repos you have access to (personal + orgs)
- Skips merge commits and dependency bot commits
- TIL angles are suggestions - Claude should refine based on context
- Notion sync prevents duplicate suggestions across machines
