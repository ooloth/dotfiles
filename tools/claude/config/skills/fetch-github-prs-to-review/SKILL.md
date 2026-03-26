---
name: fetch-github-prs-to-review
description: Fetches and processes GitHub pull requests waiting for review. Returns fully formatted markdown with PRs grouped by category (Feature/Bug, Chores, Dependency Updates) and sorted by age. Includes metadata like CI status, review status, size metrics, and viewing history. Use when user wants to see their PR review queue.
allowed-tools: [Bash]
---

# Fetching GitHub PRs to Review

Fetches pull requests waiting for review from GitHub and returns formatted markdown ready to display.

## Usage

Run the skill to get formatted markdown output:

```bash
python3 ~/.claude/skills/fetching-github-prs-to-review/fetch_prs.py
```

## What It Returns

Returns formatted markdown ready to display. Example output:

```
📋 PRs waiting for your review: 5 found | Est. total time: ~55 min

🎯 FEATURE/BUG PRs (2):

 1. **"Add user authentication" • frontend-app • @alice**
   • 💬 Implements JWT-based authentication for API endpoints
   • 📅 1 week old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +127 • 🔴 -45 • 📄 4 • ⏱️ 10m
   • 🔗 https://github.com/org/frontend-app/pull/42

 2. **"Fix memory leak in cache layer" • data-service • @david**
   • 💬 Resolves memory growth issues in Redis cache implementation
   • 📅 2 days old • ✅ CI passing • ✅ Approved • ✅ No conflicts
   • 💬 You commented 4 hours ago
   • 🟢 +89 • 🔴 -12 • 📄 2 • ⏱️ 5m
   • 🔗 https://github.com/org/data-service/pull/89

🔧 CHORES (1):

 3. **"chore: update CI pipeline" • infra-config • @frank**
   • 💬 Modernizes GitHub Actions workflows and adds caching
   • 📅 5 days old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +156 • 🔴 -89 • 📄 7 • ⏱️ 20m
   • 🔗 https://github.com/org/infra-config/pull/34

📦 DEPENDENCY UPDATES (2):

 4. 🆕 **"Bump lodash from 4.17.20 to 4.17.21" • frontend-app • @dependabot**
   • 📅 3 days old • ✅ CI passing • 👀 Review required • ✅ No conflicts
   • 🟢 +12 • 🔴 -8 • 📄 2 • ⏱️ 5m
   • 🔗 https://github.com/org/frontend-app/pull/178

 5. **"Bump express from 4.18.0 to 4.18.2" • backend-api • @dependabot**
   • 📅 1 week old • ❌ CI failing • 👀 Review required • ✅ No conflicts
   • 🟢 +9 • 🔴 -9 • 📄 2 • ⏱️ 5m
   • 🔗 https://github.com/org/backend-api/pull/201

Commands:
- Type a number (1-5) to review that PR
- After each review, I'll prompt: "Continue? (y/n/list/number)" to review more PRs

💡 Interactive workflow: Type a number → review PR → prompted for next → repeat until done
```

## Processing Done by Skill

1. Fetches PRs via GitHub GraphQL API where you're requested as reviewer
2. Calculates human-readable ages and review time estimates
3. Parses CI status, review status (counting unique reviewers), conflict status
4. Extracts PR summaries from descriptions (omitted for dependency updates)
5. Tracks viewing history (marks new PRs with 🆕 badge)
6. Groups PRs into categories (Feature/Bug → Chores → Dependency Updates)
7. Sorts by age (oldest first) within each category
8. Assigns sequential numbers across all PRs
9. Formats as markdown with proper spacing and blank lines
10. Stores lookup mapping in `~/.claude/.cache/fetching-github-prs-to-review.json`
11. Updates viewing history in `~/.claude/.cache/fetching-github-prs-to-review-history.json`

## Notes

- Filters out PRs from ignored repos (currently: `recursionpharma/build-pipelines`)
- FEATURE/BUG PRs: Not chores, not dependency updates, not drafts
- CHORES: PRs with titles starting with "chore:"
- DEPENDENCY UPDATES: All dependency updates (dependabot, bump PRs, etc.)
- Unique reviewer count: Counts each person once, shows their most recent review state
- Time estimates: Based on total lines changed (0-50: 5min, 51-200: 10min, etc.)
- Formatting: Space before PR numbers prevents markdown list parsing; blank lines separate PRs
