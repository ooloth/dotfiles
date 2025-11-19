---
name: review-queue
description: Fetches and processes GitHub pull requests waiting for review. Returns structured JSON with PRs grouped by priority (ACTION REQUIRED, HIGH PRIORITY, DEPENDABOT, CHORES) including metadata like CI status, review status, size metrics, and viewing history. Use when user wants to see their PR review queue or triage pull requests.
allowed-tools: [Bash]
---

# Review Queue Skill

Fetches pull requests waiting for review from GitHub and returns processed, prioritized data.

## Usage

Run the skill to get structured PR data:

```bash
python3 ~/.claude/skills/review-queue/fetch_prs.py
```

## What It Returns

Returns JSON with the following structure:

```json
{
  "prs": [
    {
      "seq_num": 1,
      "title": "PR title",
      "url": "https://github.com/...",
      "repo_full": "org/repo",
      "repo_short": "repo",
      "author": "username",
      "number": 123,
      "additions": 76,
      "deletions": 45,
      "files": 6,
      "age_str": "📅 1 day old",
      "age_days": 1,
      "time_estimate": "~10 min",
      "ci_status": "✅ CI passing",
      "review_status": "👀 Review required • 👥 3 reviewers (✅ 1 approved, 💬 2 commented)",
      "conflict_status": "✅ No conflicts",
      "summary": "Brief description...",
      "my_engagement": "💬 You commented 4 hours ago",
      "is_new": true,
      "category": "feature",
      "action_required": false,
      "urgency_reason": null,
      "is_draft": false
    }
  ],
  "totals": {
    "action_required": 2,
    "high_priority": 3,
    "dependabot": 5,
    "chores": 1,
    "total": 11,
    "estimated_time_mins": 135,
    "estimated_time_str": "~2h 15min"
  },
  "generated_at": "2025-11-18T17:00:49Z"
}
```

## Processing Done by Skill

1. Fetches PRs via GitHub GraphQL API where you're requested as reviewer
2. Calculates human-readable ages and review time estimates
3. Parses CI status, review status (counting unique reviewers), conflict status
4. Extracts PR summaries from descriptions
5. Tracks viewing history (marks new PRs with `is_new: true`)
6. Groups PRs into categories (ACTION REQUIRED, HIGH PRIORITY, DEPENDABOT, CHORES)
7. Sorts by urgency within each category
8. Assigns sequential numbers across all PRs
9. Stores lookup mapping in `~/.claude/.cache/review-queue.json`
10. Updates viewing history in `~/.claude/.cache/review-queue-history.json`

## Notes

- Filters out PRs from ignored repos (currently: `recursionpharma/build-pipelines`)
- ACTION REQUIRED: Failing CI, >6mo old, or >3mo old with conflicts
- HIGH PRIORITY: Feature/bug PRs (not chores, not dependabot)
- DEPENDABOT: PRs authored by dependabot
- CHORES: PRs with titles starting with "chore:"
- Unique reviewer count: Counts each person once, shows their most recent review state
- Time estimates: Based on total lines changed (0-50: 5min, 51-200: 10min, etc.)
