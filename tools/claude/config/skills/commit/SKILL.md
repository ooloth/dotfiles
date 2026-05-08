---
name: commit
description: Commit the changes in the working tree. Only invoke when the user explicitly signals to commit ("commit", "/commit", etc.). Never invoke this skill on your own initiative — implementation approval is not a commit signal.
allowed-tools: Bash
---

## Context

- Status: !`git status --short`
- All changes: !`git diff HEAD`

If Status and All changes are both empty, there is nothing to commit — say so and stop.

## Your task

1. Run all checks and fix any errors that weren't auto-fixed until you see a successful run. Discover what checks apply by consulting the project's Makefile, CI configuration (e.g. `.github/workflows/`), and CLAUDE.md.
2. Run all tests and fix any errors you encounter until all tests pass
3. Divide the changes into themes if relevant. For example, pair one test case with its implementation and corresponding documentation updates. Or one new lint rule and its fixes. Changes in one file or layer don't necessarily all belong in the same commit. **If a clean split would require writing intermediate versions of files to disk, do not split — make one commit instead.** Writing intermediate files is change replay: the committed state was never tested and may not even be correct.
4. Commit the changes yourself following the "Writing Commit Messages" style guide below. Design a commit sequence that helps readers understand how the system evolved, but do not revert and replay changes to achieve that sequence. Just do your best to divide the existing changes up sensibly. See "Workflows > Staging file hunks non-interactively" when staging some changes in a file but not others (hint: `git add -p` won't work)
5. After each commit, run `git log --oneline -3` to confirm it was recorded correctly.
6. If a precommit hook fails and addressing the failure requires a design decision the user has not made, stop and present options and wait for approval.
7. When finished making all commits, you may continue implementing your next approved task — but stop and write a status report before committing anything further. Each commit requires its own explicit user signal ("commit", "/commit", etc.). This invocation of /commit authorized only the changes present right now. It does not carry forward to future changes made later in the session.

## Writing Commit Messages

Write commit messages that follow the following style guidelines (if not superseded by guidance in the project).

### Format

```
<subsystem>: <summary>

<reference issues/PRs/etc.>

<long form description>
```

### Rules

#### Subject line

- **Subsystem prefix:** Use a short, lowercase identifier for the area of code changed (e.g., ui, api, lib, ci, config, font). Determine this from the file paths in the diff. Use nested subsystems with / when helpful and exclusive (e.g. ui/sidebar, api/health).
- **Summary:** Lowercase start (not capitalized), imperative mood, no trailing period. Keep it concise — ideally under 60 characters total for the whole subject line.

#### References

- If the change relates to a GitHub issue, PR, or discussion, list the relevant numbers on their own lines after the subject, separated by a blank line. e.g. #1234
- If there are no references, omit this section entirely (no blank line)

#### Long form description

- Describe **what changed**, **what the previous behavior was**, and **how the new behavior works** at a high level
- Use plain prose, not bullet points. Wrap lines at ~72 characters.
- Focus on the why and how rather than restating the diff
- Keep the tone direct and technical without filler phrases
- Don't exceed a handful of paragraphs; less is more
- If the commit resolves a GitHub Issue, include `Fixes #X` or `Closes #X`

## Workflows

### Staging file hunks non-interactively

When a file has multiple unrelated changes destined for different commits, use `git apply --cached` instead of `git add -p`. The latter requires a TTY and will not work in this environment.

Steps:

1.  `git diff <file> > /tmp/changes.patch`
2.  Edit `/tmp/changes.patch` to keep only the hunk(s) you want — delete unwanted `@@` blocks and their lines, keeping the file headers (`--- a/...` / `+++ b/...`)
3.  `git apply --cached /tmp/changes.patch` to stage just those hunks
4.  Commit, then stage the remaining changes normally for the next commit
