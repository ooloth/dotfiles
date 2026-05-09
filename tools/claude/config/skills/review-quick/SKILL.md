---
name: review-quick
description: Review a PR, branch or file path and recommend the highest ROI improvement opportunities. TRIGGER when the user asks if the code is ready, looks good, or is otherwise complete.
argument-hint: '[file paths or description of what to analyze]'
allowed-tools: Bash Read Grep Glob
effort: high
model: opus
---

## Your role

Orchestrate a parallel code review. Determine scope, launch all 10 agents simultaneously, then merge their findings into neutral structured output for the calling skill to format.

## Step 1: Determine scope

Identify changed files and determine the exact diff command for agents to use:

| Situation            | File list command                  | Diff command for agents    |
| -------------------- | ---------------------------------- | -------------------------- |
| PR branch            | `gh pr diff --name-only`           | `gh pr diff`               |
| Feature branch       | `git diff main...HEAD --name-only` | `git diff main...HEAD`     |
| Main, staged changes | `git diff --staged --name-only`    | `git diff --staged`        |
| Main, nothing staged | `git diff HEAD~1 --name-only`      | `git diff HEAD~1`          |
| File paths provided  | use the provided paths             | `git diff HEAD -- <files>` |

Substitute the actual base ref (main, master, trunk) where needed.

## Step 2: Review

1. Read `~/.claude/references/README.md` and these reference files to ground your evaluation
   criteria: `architecture.md`, `design.md`, `code-quality.md`, `correctness.md`, `security.md`,
   `testing.md`. Load others if the change touches data, operations, or deployment.
2. Review the code in the scope identified above across all relevant quality dimensions.
3. Identify the top 5 things we could do to improve it, ranked by criticality and ROI.
4. Present your feedback using formatting that makes each recommendation easy to scan and discuss.
