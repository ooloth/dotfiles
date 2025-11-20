---
name: scan-git-for-tils
description: Scans GitHub commit history for commits that might make good TIL blog posts. Queries all your repos across all orgs via GitHub API. Looks for bug fixes, configuration changes, gotchas, and interesting solutions. Caches assessed commits to avoid duplicates. Use when user asks for TIL ideas from their recent work.
allowed-tools: [Bash]
---

# Scan Git for TILs Skill

Analyzes recent GitHub commits across all your repos to find TIL-worthy topics.

## Usage

Run the skill to scan GitHub commit history:

```bash
python3 ~/.claude/skills/scan-git-for-tils/scan_git.py [days]
```

**Arguments:**
- `days` (optional): Number of days to look back (default: 30)

**Requirements:**
- `gh` CLI installed and authenticated
- Access to repos you want to scan

## What It Returns

Formatted markdown with TIL suggestions:

```
📝 TIL Opportunities from Git History (last 30 days):

1. **Git: Ignoring already-tracked files**
   - Commit: abc1234 "fix: properly ignore .env after initial commit"
   - Date: 3 days ago
   - Files: .gitignore, .env
   - TIL angle: Common gotcha - .gitignore doesn't affect tracked files

2. **Zsh: Fixing slow shell startup**
   - Commits: def5678, ghi9012 (related)
   - Date: 1 week ago
   - Files: .zshrc, nvm.zsh
   - TIL angle: Lazy-load slow plugins to speed up shell init

No suggestions found? Try:
- Increasing the date range
- Checking a different repository
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
2. Filters out previously assessed commits (using cache)
3. Scores commits based on TIL potential:
   - Has "fix", "resolve", "workaround" in message
   - Touches config files (.rc, .config, .json, .yaml)
   - Has detailed commit message (multiple lines or >100 chars)
   - Related to common gotcha patterns
4. Groups related commits (same files or topic)
5. Generates TIL angle suggestions based on commit content
6. Saves assessed commit hashes to cache
7. Formats output as markdown

## Cache Management

**Location:** `~/.config/claude/.cache/scan-git-for-tils-history.json`

The cache stores commit hashes that have been assessed to avoid showing the same suggestions repeatedly.

To reset and see all commits again:
```bash
rm ~/.config/claude/.cache/scan-git-for-tils-history.json
```

## Notes

- Requires `gh` CLI installed and authenticated
- Queries commits across all repos you have access to (personal + orgs)
- Skips merge commits and dependency bot commits
- TIL angles are suggestions - Claude should refine based on context
- Cache prevents duplicate suggestions across sessions
