---
description: Commit the changes in the working tree. Use every time you are committing changes.
---

## Context

- All changes: !`git diff HEAD`
- Staged changes: !`git diff --staged`
- Unstaged changes: !`git diff`

## Your task

1. Run all checks and fix any errors that weren't auto-fixed until you see a successful run
2. Run all tests and fix any errors you encounter until all tests pass
3. Divide the changes into themes if relevant. For example, pair one test case with its implementation and corresponding documentation updates. Changes in one file don't necessarily all belong in the same commit.
4. Commit the changes yourself. Ideally, sequence the commits in an order that progresses from building blocks to their integration. But do not revert and reply changes to force that sequence. Just do your best to show reviewers multiple small changes rather than a single large one when that would help their understanding.

   **Staging specific hunks non-interactively:** When a file has multiple unrelated changes destined for different commits, use `git apply --cached` instead of `git add -p` (which requires a TTY and won't work here):
   1. `git diff <file> > /tmp/changes.patch`
   2. Edit `/tmp/changes.patch` to keep only the hunk(s) you want — delete unwanted `@@` blocks and their lines, keeping the file headers (`--- a/...` / `+++ b/...`)
   3. `git apply --cached /tmp/changes.patch` to stage just those hunks
   4. Commit, then stage the remaining changes normally for the next commit

5. When finished making all commits, move on to your next known task immediately or ask me what's next. Defer all future committing to me until I specifically ask you to commit again.
