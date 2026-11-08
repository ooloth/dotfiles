# Git

Code that runs git is correct when it never gets in the way of other git work running in the
same repository.

## Should

**A git read that runs alongside other git work never refreshes the index.**
`git status` and `git diff HEAD` rewrite `.git/index` when file timestamps are stale, and take
`.git/index.lock` to do it, so a commit running at that moment fails with "index.lock exists".
`git status` skips the refresh under `GIT_OPTIONAL_LOCKS=0`, but `git diff` ignores that
variable, so line counts come from `git diff-index`. Checked against git 2.56.0.

## In scope

- Code that runs git commands: scripts, hooks, status lines and prompts
