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

1. Run all relevant checks. Fix errors that are mechanical and contained to files already in the
   diff (e.g. formatting, unused imports, trivial lint). If fixing an error would require touching
   new files, making design decisions, or adding non-trivial logic — stop, report what failed and
   why, and wait for approval before proceeding. Discover what checks apply by consulting the
   project's CONTRIBUTING.md, Justfile and CLAUDE.md.
2. Run all tests. Apply the same rule: fix only mechanical failures in files already in the diff;
   escalate anything requiring new design work.
3. Try to divide the changes into themes. For example, pair one test case with its implementation
   and corresponding documentation updates. Or one new lint rule and all its fixes. Changes in one
   file or layer don't necessarily all belong in the same commit. Design a commit sequence that
   will help readers understand how the system evolved, but do NOT design a sequence that would
   require reverting or replaying changes; that is time-consuming and introduces the risk of
   mistakes and committing unreviewed changes
4. Make each commit following the "Writing Commit Messages" style guide below. See "Workflows >
   Staging file hunks non-interactively" when staging some changes in a file but not others (hint:
   `git add -p` won't work in this environment)
5. After each commit, run `git log --oneline -3` to confirm it was recorded correctly.
6. If a precommit hook fails and addressing the failure requires a design decision the user has not
   made, stop and present options and wait for approval.
7. When finished making all commits, continue implementing your next approved task — but do not
   ever commit again unless explicitly asked to again. Each commit requires a new, explicit user
   approval signal ("commit", "/commit", etc.). The invocation of /commit you just acted on
   authorized only the changes you just finished committing. It does not carry forward.

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
