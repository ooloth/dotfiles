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

### 2. Find ready issues

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

### 3. Skip already-claimed issues

For each ready issue, check whether `status:agent-working` is also present — a previous run may have claimed it and stalled:

```bash
gh issue view <number> --repo <slug> --json labels --jq '[.labels[].name]'
```

Skip any issue that already carries `status:agent-working`. Note it in the final report.

## Implementation

### 4. Create a branch for each issue

```bash
BRANCH="claude/issue-<number>"
git -C <repo-path> checkout -b "$BRANCH"
```

### 5. Spawn one subagent per issue

For each issue, spawn a subagent and pass it:

- `repo` — GitHub slug (e.g. `ooloth/hub`)
- `issue` — issue number
- `repo-path` — absolute path to the cloned repo (identified in step 1)
- `branch` — branch name from step 4
- `dotfiles-path` — absolute path to the cloned dotfiles repo (identified in step 1)
- Instruction: read `tools/claude/config/routines/implement-issue.md` from the dotfiles repo and follow it exactly using the values above

Run subagents in parallel only when they target **different repos**. Two subagents in the same repo must run sequentially to avoid git conflicts.

## Report

```
Implemented:
  ooloth/hub #42       — opened draft PR #N: <title>
  ooloth/dotfiles #17  — opened draft PR #N: <title>

Stopped early:
  ooloth/hub #38       — open design question; relabeled status:needs-human-review (see issue comment)

Skipped (already claimed):
  ooloth/hub #51       — status:agent-working label already present
```
