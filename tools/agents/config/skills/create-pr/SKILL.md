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
   ran its checks. Then confirm from this session that `prove-it-works` has reported on the
   branch's head commit, as the `commit` skill's step 7 describes, and run it now if it hasn't.
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
5. Check whether the branch already has a PR with
   `gh pr list -R <owner>/<repo> --head <branch> --json number,url`. When one is open, save its
   body now, before anything rewrites it, with
   `gh pr view <n> -R <owner>/<repo> --json body -q .body > <saved file>`, the file in a new
   `mktemp -d` directory.
6. Use the `write-pr-description` skill, passing it the ticket from step 4 and any evidence folder
   the caller named, whose `commands.txt` it gives `check_pr_body.py` as `--commands`, to write the
   title and body to files following my voice guide. When a PR is open, or the body changed after
   that skill ran `check_pr_body.py`, run it again on `<dir>/pr-body.md`, as its step 5 says, and go
   on only once it exits 0. With a PR open, pass `--live-copy <saved file> --pr <n>`, so an edit
   someone made since step 5 is merged rather than overwritten. Then put the title and body in one
   request file, using the full path of the directory the skill names:

   ```sh
   jq -n --rawfile title <dir>/title.txt --rawfile body <dir>/pr-body.md \
     --arg head <branch> --arg base <base> \
     '{title: ($title | rtrimstr("\n")), body: $body, head: $head, base: $base, draft: true}' \
     > <dir>/pr.json
   ```

   The title then reaches GitHub from the file, not retyped into a command, and each command below
   is one plain call with literal paths, as `use-gh` asks of anything that posts.
   - With no PR yet, create it as a draft with `gh api repos/<owner>/<repo>/pulls --input
     <dir>/pr.json --jq '.number, .html_url'`, and note the number and URL it prints.
   - With a PR already open, update its title and body with
     `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> --input <dir>/pr.json --jq .html_url`, and skip
     step 7, because the ticket was linked when the PR opened. The update endpoint takes neither
     `head` nor `draft` and ignores both (seen 2026-11-17 on a draft PR), so only the title and
     body change.
   - If `<dir>/missing.txt` exists, keep its lines for the final report.
7. If the ticket is a Jira, Linear or Monday ticket, post one comment on it. On Jira through the
   MCP tool it is `Draft PR: [<owner>/<repo>#<n>](<PR URL>)`, because Jira posts a bare URL as text
   that cannot be clicked. Through acli it is the same words as ADF, with a `link` mark on
   `<owner>/<repo>#<n>`, because acli posts markdown as literal text. On Linear and Monday it is
   `Draft PR: <PR URL>`.
   Skip GitHub issues, because the PR's `Fixes #N` or `#N` already shows on the issue's timeline.
   Read `use-jira` or `use-linear` before posting. Post without asking: running this skill approves
   this comment, as the global CLAUDE.md says. If no tool can post to the tracker, the post fails,
   or `use-jira`'s check of a post through the MCP tool cannot run, give the user the line to paste
   when they ran this skill. When the user did not run this skill, put the line and the ticket in
   the final report.
8. Open the PR in the browser with `gh pr view <PR URL> --web`. Where that fails, such as in a
   sandbox with no browser, say so in one line and carry on: the PR exists either way.

End by reporting the PR's number and URL, any ticket comment that was not posted, and each line of
`missing.txt`.
