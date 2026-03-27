---
name: create-pr
description: Draft a PR for the changes on the current branch using the "commit" and "write-pr-description" skills.
disable-model-invocation: true
---

## Steps

1. Use the `commit` skill to commit all non-temporary changes in the working tree that belong in the PR
2. Run quality checks (formatting, linting, types, tests) and fix all failures
3. Use the `write-pr-description` skill to draft and create the PR following my voice guide
4. Open the PR in the browser with `gh pr view --web`
