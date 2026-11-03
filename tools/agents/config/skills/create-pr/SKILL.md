---
name: create-pr
description: Open a draft PR for the changes on the current branch using the "commit" and "write-pr-description" skills, link it on its ticket, then open it in the browser. Run it when the user asks, or as the step that opens the draft PR in "Working Through to a Draft PR".
---

"The user ran this skill" below means the user invoked `create-pr` themselves. Inside "Working
Through to a Draft PR", another skill or an unattended run, the work doesn't stop for a question, so
this skill asks nothing there and puts what it would have asked in its final report.

## Steps

1. Run quality checks (formatting, linting, types, tests), unless they already passed on the
   current branch earlier in this session with nothing changed since. If any fail when the user
   ran this skill, fix them and stop so the user can review the fixes. Inside "Working Through
   to a Draft PR" or another skill, fix what is mechanical and carry on, since the caller already
   ran its checks.
2. Use the `commit` skill to commit the non-temporary changes in the working tree that belong in
   the PR.
3. Push the branch as the `commit` skill's step 7 describes, with `git push -u origin <branch>` so
   it tracks the remote. Push even when step 2 had nothing to commit: the branch may hold commits
   the remote doesn't have yet. When CI failed on the remote branch's last commit, ask before
   pushing when the user ran this skill. Otherwise stop before pushing, and put the failing
   workflow and commit in the final report.
4. Find the ticket the work is tracked by: a Jira, Linear or Monday key, or a GitHub issue, from the
   branch name, the commits, or the ticket the session's task is on. A key that only appears as a
   related link is not the ticket. If more than one ticket fits, or none does, ask when the user
   ran this skill. Otherwise treat it as no ticket and name the candidates in the final report.
5. Check whether the branch already has a PR with `gh pr list --head <branch> --json number,url`.
6. Use the `write-pr-description` skill, passing it the ticket from step 4, to write the title and
   body to files following my voice guide. Then:
   - With no PR yet, create it as a draft:
     `gh pr create --draft --title "$(cat <dir>/title.txt)" --body-file <dir>/pr-body.md`, using
     the full path of the directory the skill names. Reading the title through `$(cat ...)` keeps
     backticks in it literal. Note the PR number and URL it prints.
   - With a PR already open, update it with
     `gh pr edit <n> --title "$(cat <dir>/title.txt)" --body-file <dir>/pr-body.md`, and skip step
     7, because the ticket was linked when the PR opened.
7. If the ticket is a Jira, Linear or Monday ticket, post one comment on it: `Draft PR: <PR URL>`.
   Skip GitHub issues, because the PR's `Fixes #N` or `#N` already shows on the issue's timeline.
   Read `use-jira` or `use-linear` before posting. Post without asking: running this skill approves
   this comment, as the global CLAUDE.md says. If no tool can post to the tracker, or the post
   fails, give the user the line to paste when they ran this skill. Otherwise put the line and the
   ticket in the final report.
8. Open the PR in the browser with `gh pr view <PR URL> --web`. Where that fails, such as in a
   sandbox with no browser, say so in one line and carry on: the PR exists either way.

End by reporting the PR's number and URL, and any ticket comment that was not posted.
