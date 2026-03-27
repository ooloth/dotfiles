---
name: fetch-github-prs-to-review
description: Fetches and processes GitHub pull requests waiting for review. Returns fully formatted markdown with PRs grouped by category (Feature/Bug, Chores, Dependency Updates) and sorted by age. Includes metadata like CI status, review status, size metrics, and viewing history. Use when user wants to see their PR review queue.
allowed-tools: [Bash]
---

# Fetching GitHub PRs to Review

Fetches pull requests waiting for review from GitHub and returns formatted markdown ready to display.

## Context

- PRs with my review requested: !`python3 ~/.claude/skills/fetch-github-prs-to-review/fetch_prs.py`

### What the script above does

1. Fetches PRs via GitHub GraphQL API where you're requested as reviewer
2. Calculates human-readable ages and review time estimates
3. Parses CI status, review status (counting unique reviewers), conflict status
4. Extracts PR summaries from descriptions (omitted for dependency updates)
5. Tracks viewing history (marks new PRs with 🆕 badge)
6. Groups PRs into categories (Feature/Bug → Chores → Dependency Updates)
7. Sorts by age (oldest first) within each category
8. Assigns sequential numbers across all PRs
9. Formats as markdown with proper spacing and blank lines
10. Stores lookup mapping in `~/.claude/.cache/fetch-github-prs-to-review.json`
11. Updates viewing history in `~/.claude/.cache/fetch-github-prs-to-review-history.json`

### Notes

- Filters out PRs from ignored repos (currently: `recursionpharma/build-pipelines`)
- FEATURE/BUG PRs: Not chores, not dependency updates, not drafts
- CHORES: PRs with titles starting with "chore:"
- DEPENDENCY UPDATES: All dependency updates (dependabot, bump PRs, etc.)
- Unique reviewer count: Counts each person once, shows their most recent review state
- Time estimates: Based on total lines changed (0-50: 5min, 51-200: 10min, etc.)
- Formatting: Space before PR numbers prevents markdown list parsing; blank lines separate PRs

## Workflow

1. Show the user the output of the script above immediately
2. Offer the user an interactive workflow: user types a number or otherwise chooses a PR → you review PR using `review-pr` skill → you show user updated list of remaining PRs and prompt for next choice → repeat until done
