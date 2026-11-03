---
name: create-pr
description: Open a draft PR for the changes on the current branch using the "commit" and "write-pr-description" skills, link it on its ticket, then open it in the browser. Run it when the user asks, or as the step that opens the draft PR in "Working Through to a Draft PR".
---

## Steps

1. Run quality checks (formatting, linting, types, tests), unless they already passed on the
   current branch earlier in this session with nothing changed since. If any fail when the user
   invoked this skill, fix them and stop so the user can review the fixes. Inside "Working Through
   to a Draft PR" or another skill, fix what is mechanical and carry on, since the caller already
   ran its checks.
2. Use the `commit` skill to commit the non-temporary changes in the working tree that belong in
   the PR.
3. Push the branch as the `commit` skill's step 7 describes, with `git push -u origin <branch>` so
   it tracks the remote. Push even when step 2 had nothing to commit: the branch may hold commits
   the remote doesn't have yet.
4. Use the `write-pr-description` skill to write the description to a file following my voice
   guide, then create the PR as a draft with
   `gh pr create --draft --title "<title>" --body-file <that file's full path>`.
5. If the work is tracked by a Jira, Linear or Monday ticket, post one comment on it:
   `Draft PR: <PR URL>`. Find the ticket from a key in the branch name, PR title or body, or from
   the session. Skip GitHub issues, because the PR's `Fixes #N` or `#N` already shows on the
   issue's timeline. Read `use-jira` or `use-linear` before posting. Post without asking, since
   opening the PR approves this comment. If the ticket is unclear, ask rather than guess. If no
   tool can post to the tracker, give the user the line to paste.
6. Open the PR in the browser with `gh pr view --web`. Where that fails, such as in a sandbox with
   no browser, say so in one line and carry on: the PR exists either way.
