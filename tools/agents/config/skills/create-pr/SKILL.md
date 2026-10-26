---
name: create-pr
description: Draft a PR for the changes on the current branch using the "commit" and "write-pr-description" skills.
disable-model-invocation: true
---

## Steps

1. Run quality checks (formatting, linting, types, tests). If any fail, fix them and stop so the
   user can review the fixes.
2. Use the `commit` skill to commit the non-temporary changes in the working tree that belong in
   the PR
3. Use the `write-pr-description` skill to draft and create the PR following my voice guide
4. Open the PR in the browser with `gh pr view --web`
