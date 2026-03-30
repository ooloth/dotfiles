---
name: commit
description: Commit the changes in the working tree. Use every time you are committing changes.
---

## Context

- All changes: !`git diff HEAD`
- Staged changes: !`git diff --staged`
- Unstaged changes: !`git diff`

## Your task

1. Run all checks and fix any errors that weren't auto-fixed until you see a successful run
2. Run all tests and fix any errors you encounter until all tests pass
3. Divide the changes into themes if relevant. For example, pair one test case with its implementation and corresponding documentation updates. Or one new lint rule and its fixes. Changes in one file or layer don't necessarily all belong in the same commit.
4. Commit the changes yourself following the "Writing Commit Messages" style guide below. Design a commit sequence that helps readers understand how the system evolved, but do not revert and replay changes to achieve that sequence. Just do your best to divide the existing changes up sensibly. See "Workflows > Staging file hunks non-interactively" when staging some changes in a file but not others (hint: `git add -p` won't work)
5. When finished making all commits, move on to your next known task immediately or ask me what's next. Defer all future committing to me until I specifically ask you to commit again.

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
- Keep the tone direct and technical without no filler phrases
- Don't exceed a handful of paragraphs; less is more.

## Workflows

### Staging file hunks non-interactively

When a file has multiple unrelated changes destined for different commits, use `git apply --cached` instead of `git add -p`. The latter requires a TTY and will not work in this environment.

Steps:

1.  `git diff <file> > /tmp/changes.patch`
2.  Edit `/tmp/changes.patch` to keep only the hunk(s) you want — delete unwanted `@@` blocks and their lines, keeping the file headers (`--- a/...` / `+++ b/...`)
3.  `git apply --cached /tmp/changes.patch` to stage just those hunks
4.  Commit, then stage the remaining changes normally for the next commit
