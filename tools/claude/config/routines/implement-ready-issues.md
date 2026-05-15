## Purpose

Finds all GitHub issues labeled `status:ready-for-agent` across a set of pre-cloned repos, implements each one autonomously in an isolated git worktree, and opens a draft PR. Designed to run as a Claude Code Routine where repos are pre-cloned into the workspace.

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

### 4. Prepare a worktree for each issue

For each issue to implement, create an isolated worktree:

```bash
BRANCH="claude/issue-<number>"
WORKTREE="/tmp/worktrees/<repo-name>-issue-<number>"

git -C <repo-path> worktree add "$WORKTREE" -b "$BRANCH"
```

### 5. Spawn one subagent per issue

For each issue, spawn a subagent and pass it:

- `repo` — GitHub slug (e.g. `ooloth/hub`)
- `issue` — issue number
- `worktree` — absolute path prepared in step 4
- `branch` — branch name from step 4
- Instruction: read `prompts/implement-issue.md` from the cloned repo at that path and follow it exactly using the values above

Run subagents in parallel only when they target **different repos**. Two subagents in the same repo must run sequentially to avoid git conflicts.

## Cleanup

### 6. Remove worktrees

After each subagent completes (whether it opened a PR or stopped early), remove its worktree:

```bash
git -C <repo-path> worktree remove "$WORKTREE" --force
```

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
