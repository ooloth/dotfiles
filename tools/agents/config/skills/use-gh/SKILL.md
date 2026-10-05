---
name: use-gh
description: gh CLI gotchas that waste context or post malformed comments and reviews to real PRs and issues. Read before every gh invocation, reads included, because default output silently omits comments and relationships and a bad post cannot be un-notified. Re-invoke each time.
allowed-tools: [Bash, Read]
---

## The core rule: never post to find out if it worked

Posting a comment or review is not reversible the way editing a file is. Every comment creation
notifies whoever's watching the PR/issue, and it stays in the timeline even if you fix it a
moment later. So a "test comment" to check the command works, followed by a real one, followed
by a "sorry, ignore the above" — is three notifications and a visibly dirty trail, not one.

Before running anything that posts, validate the body in your own context first:

- Write the body to a file (Write tool) and read it back to confirm it renders the way you
  intend — check for broken code fences, mis-escaped characters, the right line references.
- Check the constructed command against `--help` if you're unsure of a flag, rather than running
  it once to see what happens.

Only post once you'd be fine with that exact content landing in front of the user right now.

## If you do post something wrong: edit or delete, don't pile on

`gh pr comment` and `gh issue comment` both support:

- `--edit-last` — edits your own last comment on that PR/issue. This does **not** send a new
  notification (GitHub only notifies on comment creation, not edits), so it's the clean fix —
  strictly better than posting a follow-up "correction" comment, which notifies again and leaves
  two entries where one would do.
- `--delete-last` — removes your own last comment outright (prompts for confirmation; `--yes`
  skips it).

`gh pr review` has **no `--edit-last`**. A submitted review (`--approve`, `--comment`,
`--request-changes`) can't be edited via `gh` the way a plain comment can — `--approve`
particularly can't be un-approved from the CLI at all (only dismissed from the web UI, and the
dismissal itself is visible history). Reviews get exactly one shot: validate the body and the
event type before submitting, not after.

## Body-content mistakes that cause the bad first post

- **Shell-escaping in inline `-b/--body` strings.** Backticks, `$()`, and quotes get interpreted
  by the shell before `gh` ever sees them — this is the single most common cause of a mangled
  first post. Write the body to a file (Write tool, not a bash heredoc) and pass
  `-F/--body-file <path>` instead. Supported by `gh pr comment`, `gh issue comment`,
  `gh pr review`, `gh pr create`, `gh issue create`, and `gh pr edit`.
- **Hard-wrapped prose.** GitHub renders every newline in an issue, PR description, comment or
  review as a line break, so a paragraph wrapped at 80 or 100 columns shows up as ragged short
  lines. Each paragraph, list item and table row in a body is one line, and the GitHub UI wraps
  it. This holds even though the skill and doc files you are reading are hard wrapped: they are
  edited as plain text, and a GitHub body is read rendered. Before posting, check the body file
  for a line break inside a paragraph or list item.
- **Multi-comment PR reviews via `gh api`.** `-f key=value`/`-F key=value` is a flat syntax; it
  can express one nested level (`key[subkey]=value`, `key[]=value`) but gets unwieldy fast for an
  array of `{path, line, side, body}` objects. Write the full JSON payload to a file and pass it
  with `--input <path>` (`gh api repos/{owner}/{repo}/pulls/{n}/reviews --input review.json`)
  instead of assembling it through repeated `-f`/`-F` flags — one file you can read back and
  verify beats a command line you can't.
- **Inline comment line numbers.** Use `line`+`side`, which map directly to a line in the current
  file. Avoid `position`, which counts against diff hunk offsets and silently lands the comment
  on the wrong line if you get the offset wrong — that's a delete-and-repost, not an edit.

## Default output hides comments and relationships

`gh issue view N` and `gh pr view N` print the body only, so you read a stale picture with no hint
anything is missing.

- **Read the comments.** On a long-running issue the current plan usually lives in a comment, not
  the body. `--comments` cannot be combined with `--json`, so ask for them as a field instead:
  `gh issue view N --json title,body,comments`.
- **Ask for relationships by name.** `parent`, `subIssues`, `blockedBy` and `blocking` are
  `--json` fields on `gh issue view` and `gh issue list` (gh 2.102), and are never printed unless
  requested: `gh issue view N --json parent,blockedBy,blocking,subIssues`.
- **Put ordering in the title.** Default `gh issue list` output shows no relationships, so an
  ordering signal that must reach an agent belongs where that output prints it for every row.

## Other gotchas worth avoiding

- **Context bloat from unfiltered reads.** `gh pr view N --json files -q '.files[].path'`, not
  the unfiltered `--json files` — the latter includes `patch`/`blob_url`/`raw_url` per file,
  which adds up fast on a PR with many files.
- **Unknown `--json` field names.** `gh pr view --json <bogus>` errors out and lists every valid
  field name — cheaper than guessing or searching docs.
- **Silent pagination truncation.** `gh api --paginate` for any list endpoint that can exceed one
  page (comments, reviews, commits) — without it you can get a truncated result and mistake it
  for "that's everything."
- **Wrong-repo actions in multi-repo sessions.** Pass `-R owner/repo` explicitly rather than
  relying on the cwd's git remote.
