---
description: Create a draft pull request from the current branch
allowed-tools: [Bash, Read, Grep, Glob, Task]
---

Create a draft pull request from the current branch to the main branch.

**Target branch (optional):** $ARGUMENTS

**Process:**
1. Check current branch (must not be main/master)
2. Check working tree for uncommitted changes:
   - Review each change to determine if it belongs with the current PR
   - **Be cautious with temporary changes**: commented-out code, debug prints, config tweaks for testing
   - Ask user before committing anything that looks temporary or experimental
   - For legitimate changes: commit them with the PR
   - For unrelated changes: determine best approach (stash, separate commit, or leave uncommitted)
3. Ensure branch is up to date with latest changes from target branch
4. Ensure branch is pushed to remote
5. Analyze commits since branching from main to understand the changes
6. Read modified files to understand the full scope
7. Check if PR relates to existing project plans or issues and ensure they're updated:
   - Look for related GitHub issues, project roadmaps, or planning documents
   - Check if task tracking files (like `.claude/tasks/*.md`) need updates
   - Verify project documentation reflects the changes being made
8. Generate PR description using pr-writer agent:
   - Use the Task tool with pr-writer agent to analyze changes and craft PR description
   - Provide the agent with commit history, changed files, and any related issues/plans
   - Let the pr-writer agent handle PR template detection and description formatting
   - The pr-writer agent will ensure proper structure, tone, and reviewer experience

9. Create the draft PR with descriptive title and structured body

**GitHub CLI commands to use:**
- `git branch --show-current` - Get current branch
- `git fetch origin` - Get latest remote changes
- `git merge-base HEAD origin/main` - Check if up to date
- `git log main..HEAD --oneline` - See commits since branching
- `git diff main...HEAD --name-only` - See changed files
- `gh issue list` - Check for related GitHub issues
- Check for `.claude/tasks/*.md`, project roadmaps, or planning documents
- `gh pr create --draft` - Create draft PR

**If target branch is specified as argument, use that instead of main.**

**PR title format:** Use the branch name or first commit message as basis, make it descriptive and clear.