---
name: scan-git-for-tils
description: Scans git history for commits that might make good TIL blog posts. Looks for bug fixes, configuration changes, gotchas, and interesting solutions. Returns a formatted list of suggestions with commit context. Use when user asks for TIL ideas from their recent work.
allowed-tools: [Bash]
---

# Scan Git for TILs Skill

Analyzes recent git commits to find TIL-worthy topics.

## Usage

Run the skill to scan git history:

```bash
python3 ~/.claude/skills/scan-git-for-tils/scan_git.py [days] [repo_path]
```

**Arguments:**
- `days` (optional): Number of days to look back (default: 30)
- `repo_path` (optional): Path to git repo (default: current directory)

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

1. Fetches git log for specified date range
2. Parses commit messages, files changed, and dates
3. Scores commits based on TIL potential:
   - Has "fix", "resolve", "workaround" in message
   - Touches config files (.rc, .config, .json, .yaml)
   - Has detailed commit message (multiple lines or >100 chars)
   - Related to common gotcha patterns
4. Groups related commits (same files or topic)
5. Generates TIL angle suggestions based on commit content
6. Formats output as markdown

## Notes

- Requires git to be installed and repo to have commits
- Only analyzes commits by the current git user
- Skips merge commits and dependency bot commits
- TIL angles are suggestions - Claude should refine based on context
