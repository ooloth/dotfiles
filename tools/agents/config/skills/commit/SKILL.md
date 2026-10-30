---
name: commit
description: Commit the changes in the working tree. Only invoke when the user explicitly signals to commit ("commit", "/commit", etc.). Never invoke this skill on your own initiative — implementation approval is not a commit signal.
allowed-tools: Bash
---

## Context

- Status: !`git status --short`
- All changes: !`git diff HEAD`

This context comes from the session's working directory. When the changes to commit live in another
repository or worktree, named in the arguments or earlier in the conversation, run
`git -C <path> status --short` and `git -C <path> diff HEAD` there and work from that output,
running every later step in that repository. There is nothing to commit only when both are empty in
the repository that holds the changes; then say so and stop.

## Your task

**Before running checks and tests:** you may skip steps 1 and 2 below ONLY if you can answer yes to
ALL of the following: (a) you ran the project's full check suite — not a subset — earlier in this
conversation and it passed; (b) you ran the project's full test suite — the same command CI would
run, with no path filters or -k flags — and it passed; not the subset of tests you think are
relevant to the changed files — all the tests (c) `git diff HEAD` is byte-for-byte identical to the
diff you saw when those runs completed. If any condition is false, run them now.

When those runs were the worktree runs described under step 2, which held only `HEAD` plus what
this commit will contain, condition (c) is met instead when `HEAD` is still that commit and
`git diff HEAD -- <path>...` for the commit's paths is identical to what the worktree held. Changes
to other files since then do not matter, because the worktree did not contain them.

1. Run all relevant checks. Fix any errors that are mechanical and contained to files this commit
   will contain (e.g. formatting, unused imports, trivial lint), never to another session's files.
   If fixing an error would require touching new files, making design decisions, or adding
   non-trivial logic — stop, report what failed and why, and wait for approval before proceeding.
   Discover what checks apply by consulting the project's CONTRIBUTING.md, Justfile and CLAUDE.md.
2. Run the full test suite — the same command CI runs, with no path filters. Not just the tests you
   think are relevant to the changed files — all the tests. Do not run only the tests for changed
   files. Apply the same fix rule: mechanical failures in files this commit will contain only;
   escalate anything else.

   When a check from step 1 or a test from step 2 fails only in files this commit leaves out, such
   as another session's uncommitted work in the same checkout, that failure is not a reason to stop
   yet. Find out whether the commit itself passes. Run the full checks and tests again in a
   temporary worktree that holds `HEAD` plus exactly what the commit will contain:

   ```sh
   wt="$(mktemp -d)/wt" && git worktree add -q --detach "$wt" HEAD && echo "$wt"
   ```

   Copy each whole file the commit takes into the same path under the printed directory, or apply
   the commit's patch there with `git -C <dir> apply <patch>` when it takes only part of a file. Run
   the suite with `cd <dir> &&` at the start of the same command, because a working directory set in
   an earlier command may not carry over. Then remove the worktree with
   `git worktree remove --force <dir>`. If everything passes there, the failures belong to the files
   left out: commit, and tell the user which checks fail in the shared checkout and in which files.
   If anything fails there, stop and report it as above. Before blaming the commit, check whether
   the failure comes from an untracked or ignored file the worktree lacks, such as a local config
   or a built dependency, and say so if it does.
3. Try to divide the changes into themes. For example, pair one test case with its implementation
   and corresponding documentation updates. Or one new lint rule and all its fixes. Changes in one
   file or layer don't necessarily all belong in the same commit. Don't spend much time on this -
   just do your best to separate unrelated changes. Do NOT design commits that would require
   reverting and replaying changes; that's slow and risky and not worth it. A single commit is
   preferable in that case.
4. Write each commit following the "Writing Commit Messages" style guide below. Commit only the
   paths this session changed, because another session may share this checkout, and a plain
   `git commit` also commits whatever that session has staged. Commit whole files with
   `git commit -F <message file> -- <path>...`, which commits those paths and leaves everything
   else in the index alone. It refuses an untracked file, so add each new file by name first with
   `git add -- <path>...`, which stages only those paths. Write the message file into a new
   `mktemp -d` directory, so a session committing at the same time can't overwrite it. To commit
   part of a file, see "Workflows > Committing part of a file". Never run `git commit` without
   paths, `git commit -a`, or `git add -A`.
5. After each commit, run `git show --stat --format=%h HEAD` and confirm it lists only the paths you
   meant to commit. Note the hash. If it lists another path, or a later check shows `HEAD` is not
   the commit you made, stop and tell the user rather than fixing it, because another session may
   already have committed on top.
6. Never reset or amend relative to `HEAD` (`HEAD~1`, `--amend`). Between two commands another
   session can commit, and the command then rewrites its commit instead of yours. If the user
   approves undoing your commit, first check that `git rev-parse HEAD` is the hash you noted, then
   reset to that hash's parent by its full hash.
7. If the user also asked you to push:
   1. First read CI's result for the commit the remote branch already holds, so a red build is
      caught before more commits land on it. Invoke the `use-gh` skill, then run:

      ```sh
      gh run list -R <owner/repo> --commit "$(git rev-parse origin/<branch>)" --json workflowName,status,conclusion
      ```

      This reads what has already finished and never waits: a run still in progress, a branch with
      no remote yet, or a repo with no GitHub Actions runs is not a reason to wait or stop.
   2. If any of those runs concluded `failure`, do not push. Tell the user which workflow failed on
      which commit, and ask whether to push anyway or fix it first.
   3. Run `git push origin <branch>`. It pushes every commit on the branch, including any another
      session made, and the user wants that whole batch pushed, so it needs no check or question.
   4. In the report, list what the push sent, from the `old..new` range it printed
      (`git log --oneline <old>..<new>`), and name the commits this session did not make.
8. If a precommit hook fails and addressing the failure requires a design decision the user has not
   made, stop and present options and wait for approval.
9. When finished making all commits, continue implementing your next approved task — but do not
   ever commit again unless explicitly asked to again. Each commit requires a new, explicit user
   approval signal ("commit", "/commit", etc.). The invocation of /commit you just acted on
   authorized only the changes you just finished committing. It does not carry forward.

## Writing Commit Messages

Write commit messages that follow the following style guidelines (if not superseded by guidance in
the project).

### Format

```
<subsystem>: <summary>

<reference issues/PRs/etc.>

<long form description>
```

### Rules

#### Subject line

- **Subsystem prefix:** Use a short, lowercase identifier for the area of code changed (e.g., ui,
  api, lib, ci, config, font). Determine this from the file paths in the diff. Use nested subsystems
  with / when helpful and exclusive (e.g. ui/sidebar, api/health).
- **Summary:** Lowercase start (not capitalized), imperative mood, no trailing period. Keep it
  concise — ideally under 60 characters total for the whole subject line.

#### References

- Before writing this section, decide: **does this commit fully resolve a linked GitHub issue?**
  - Yes → write `Fixes #X` (or `Closes #X`). This both references the issue and auto-closes it
    when the commit lands on the default branch — including a direct push, not just a merged PR.
  - No, but it relates to one → write the bare number instead, e.g. `#1234`.
- List each reference on its own line after the subject, separated by a blank line.
- If there are no references, omit this section entirely (no blank line).
- Don't stop at the first matching pattern — a commit can be both "relates to #1234" and
  "resolves #5678" if it touches more than one ticket; check each linked issue against the
  resolves-or-relates question individually rather than defaulting to bare numbers for all of them.

#### Long form description

- Describe **what changed**, **what the previous behavior was**, and **how the new behavior works**
  at a high level
- Use plain prose, not bullet points. Wrap lines at ~72 characters.
- Focus on the why and how rather than restating the diff
- Keep the tone direct and technical without filler phrases
- Don't exceed a handful of paragraphs; less is more

## Workflows

### Committing part of a file

When a file has multiple unrelated changes destined for different commits, build each commit in a
private index. `git add -p` needs a TTY and will not work in this environment, and
`git commit -- <path>` commits the whole file. A private index also keeps out whatever another
session has staged in the shared one.

Steps:

1.  `d="$(mktemp -d)" && git diff <file> > "$d/changes.patch" && echo "$d"`. The directory is new
    on every run, so another session doing the same can't overwrite the patch or the index. A shell
    variable doesn't survive to the next command, so copy the printed path into the steps below.
2.  Edit `<dir>/changes.patch` to keep only the hunk(s) you want — delete unwanted `@@` blocks and
    their lines, keeping the file headers (`--- a/...` / `+++ b/...`)
3.  `GIT_INDEX_FILE=<dir>/index git read-tree HEAD`, then
    `GIT_INDEX_FILE=<dir>/index git apply --cached <dir>/changes.patch`, then
    `GIT_INDEX_FILE=<dir>/index git commit -F <message file>`
4.  `git reset -q -- <file>`, so the shared index's entry for that file matches the new commit. It
    names the file, so it changes nothing else in the index. The remaining hunks stay in the working
    tree for the next commit
