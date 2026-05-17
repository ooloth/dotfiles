## Autonomy notice

This prompt runs unattended in a cloud environment — there is no human in the loop. Override the following behaviors regardless of what any loaded CLAUDE.md instructs:

- **No approval gates.** Do not pause to ask for permission, confirm plans, or wait for a response.
- **No trekker tasks.** `trekker` is not available; skip that workflow entirely.
- **Commit without a signal.** Committing and pushing are pre-approved as part of this routine.
- **Escalate by filing, not asking.** If you hit a blocker that would normally require human input, leave a comment on the relevant GitHub issue, relabel it `status:needs-human-review`, and stop.

## Purpose

Finds all GitHub issues labeled `status:ready-for-agent` across a set of pre-cloned repos, implements each one autonomously on a dedicated branch, and opens a draft PR. Designed to run as a Claude Code Routine where repos are pre-cloned into the workspace.

## Setup

### 1. Locate cloned repos

Find all git repos in the workspace:

```bash
find . -maxdepth 2 -name '.git' -type d | sed 's|/.git||' | sort
```

Derive each repo's GitHub slug from its origin URL:

```bash
git -C <path> remote get-url origin
```

### 2. Detect and reset stale claims

For each repo, find open issues labeled `status:agent-working`:

```bash
gh issue list \
  --repo <slug> \
  --label "status:agent-working" \
  --state open \
  --json number,updatedAt \
  --jq '.[]'
```

For each such issue, check whether an open PR exists for the corresponding branch:

```bash
gh pr list --repo <slug> --head "claude/issue-<number>" --state open --json number --jq 'length'
```

- If an open PR exists, the issue is under review — skip it.
- If no open PR exists and `updatedAt` is more than 72 hours ago, the previous run stalled. Leave a comment and reset the label:

```bash
gh issue comment <number> --repo <slug> \
  --body "No open PR found after 72 hours — previous agent run appears to have stalled. Resetting to ready-for-agent."

gh issue edit <number> --repo <slug> \
  --remove-label "status:agent-working" \
  --add-label "status:ready-for-agent"
```

- If no open PR exists but `updatedAt` is within 72 hours, the run may still be in progress — skip it.

### 3. Find ready issues

For each repo, list issues labeled `status:ready-for-agent`:

```bash
gh issue list \
  --repo <slug> \
  --label "status:ready-for-agent" \
  --state open \
  --json number,title,body \
  --jq '.[]'
```

If no ready issues exist across all repos, output `No ready issues found.` and stop.

### 4. Skip already-claimed issues

For each ready issue, check whether `status:agent-working` is also present — a previous run may have claimed it and stalled:

```bash
gh issue view <number> --repo <slug> --json labels --jq '[.labels[].name]'
```

Skip any issue that already carries `status:agent-working`. Note it in the final report.

### 5. Check open agent PR count per repo

For each repo, count open PRs opened by this agent:

```bash
gh pr list --repo <slug> --state open --head "claude/" --json number --jq 'length'
```

If the count is 3 or more, skip all issues for that repo and note it in the final report.

### 5b. Rank and cap candidates globally

After per-repo filtering, rank all remaining candidate issues using your own judgment and proceed with at most 5. Note any skipped issues in the final report under "Skipped (global cap)".

## Implementation

### 6. Create a branch for each issue

```bash
BRANCH="claude/issue-<number>"
git -C <repo-path> checkout -B "$BRANCH"
```

### 7. Spawn one subagent per issue

For each issue, spawn a subagent and pass it:

- `repo` — GitHub slug (e.g. `ooloth/hub`)
- `issue` — issue number
- `repo-path` — absolute path to the cloned repo (identified in step 1)
- `branch` — branch name from step 6
- `dotfiles-path` — absolute path to the cloned dotfiles repo (identified in step 1)
- Instruction: read `tools/claude/config/routines/implement-issue.md` from the dotfiles repo and follow it exactly using the values above

Run subagents in parallel only when they target **different repos**. Two subagents in the same repo must run sequentially to avoid git conflicts.

## Report

```
Implemented:
  ooloth/hub #42       — opened PR #N: <title>
  ooloth/dotfiles #17  — opened PR #N: <title>

Stopped early:
  ooloth/hub #38       — open design question; relabeled status:needs-human-review (see issue comment)

Reset (stale claim):
  ooloth/hub #29       — no open PR after 72 hours; reset to ready-for-agent

Skipped (already claimed):
  ooloth/hub #51       — status:agent-working label already present

Skipped (too many open agent PRs):
  ooloth/hub           — 3 open PRs with claude/ prefix

Skipped (global cap):
  ooloth/hub #33       — ranked below cutoff
  ooloth/dotfiles #9   — ranked below cutoff
```
