---
name: use-jira
description: Jira gotchas for the Atlassian MCP tools and the acli CLI. Covers the cloud ID that works, reads that silently omit comments, fields and paging that make responses too large or incomplete, and markdown that Jira's conversion breaks in posted comments and descriptions, with a check to run on every markdown body before posting it through the MCP tool. Read before every Jira tool call, reads included, because a bad post notifies watchers and stays in the history. Re-invoke each time.
---

## Cloud ID

Pass the value of `$PRIVATE_JIRA_CLOUD_ID` as `cloudId`: run `echo "$PRIVATE_JIRA_CLOUD_ID"` to
read it. It is the site whose hostname `$PRIVATE_JIRA_SITE` holds. A site with a similar hostname,
such as one named after the GitHub org, is a different site this account is not granted, and the
call fails with "isn't explicitly granted by the user". Call `getAccessibleAtlassianResources` only
when that ID is refused, or when the variable is empty because this machine's `private.env` doesn't
set it.

## Reads omit comments

`getJiraIssue` returns no comments unless `fields` includes `"comment"`, and nothing in the output
says they were left out. On a ticket that has been worked on, the current plan is usually in a
comment, so ask for them on every read:

```json
"fields": ["summary", "description", "status", "comment", "parent", "issuelinks"]
```

Pass `"responseContentFormat": "markdown"` to read bodies as text rather than ADF.

## Keep responses small

A response too large to return inline is saved to a file instead, and parsing that file costs more
than asking for less. Two kinds of field cause it, and paging hides results:

- **`parent` and `issuelinks` embed whole issues.** Each one carries the linked issue's summary,
  status, priority and issue type, so a search for seven tickets with `issuelinks` came back at
  171,000 characters. To check what a set of tickets is, search with `["summary", "status"]` only.
  Ask for `issuelinks` on the one ticket whose links matter, with `getJiraIssue`.
- **`comment` and `description` are the long fields.** Request them when the plan or the body is
  what you came for, and leave them out of a search that only lists tickets.
- **A search returns one page.** When the response has `"isLast": false`, the rest of the results
  are behind its `nextPageToken`, and nothing else says they were cut off. Pass `maxResults` above
  the number of tickets you expect, or narrow the query, before treating the results as complete.

Saved responses come in more than one shape. One saved issue was the bare issue object, and one
saved search was `[{"type": "text", "text": "<JSON string>"}]` wrapping the results, so read the
first bytes of the file before parsing it.

## Markdown that Jira's conversion breaks

Posting with `contentFormat: "markdown"` converts the body to Jira's own format, and some markdown
does not survive. Most of it posts without error and renders wrong, so check every markdown body
before posting it, a comment or a description, a fix to a posted comment included:

1. Write the body with the Write tool to a file in a new directory from `mktemp -d`.
2. Run `uv run <skill-base-dir>/scripts/check_jira_markdown.py <file>`.
3. On exit 0, post the file's text exactly as it is: Read the file and pass that text, rather than
   typing the body again. On exit 2 the check did not run, which is never a pass: fix what stderr
   names and run it again.
4. On exit 1, fix each line it prints and run it again. A fix that keeps every word of approved
   text in the same order, such as moving backticks out of a bold phrase or writing a URL as
   `[url](url)`, is posted without asking again; say what changed. The check offers one of these
   only when the fixed text still reads as written. A fix that adds, drops, changes or reorders a
   word, such as a label for a link, is a new draft that waits for approval. Exit 1 is a list only
   when its last line ends `post nothing until then`. Exit 1 without that line means the check did
   not run, for example because `uv` could not install `markdown-it-py`: read the error.
5. If the check still cannot run, post nothing. On the work laptop `uv` fetches `markdown-it-py`
   only after `gcloud auth login --update-adc`, as `CONTRIBUTING.md` in the dotfiles repo
   describes, whatever command uv's own error suggests. That login opens a browser, so ask the user
   to run it, then run the check again. When the check still cannot run, give the user the body and
   the error, or put both in the final report of a run nobody is watching.

In Claude Code a `PreToolUse` hook in the dotfiles `settings.json` runs the same check on every
markdown body sent to `addCommentToJiraIssue`, `createJiraIssue` or `editJiraIssue`, and refuses
the post with the check's report as the reason. It refuses the post too when the check cannot run.
The steps above still apply, because they catch the problem before the user approves the text, and
because other agents have no hook.

The check covers these:

- **Inline code inside bold.** Jira ends the bold where the code starts:
  `**New client in `x` (chosen)**` renders with only "New client in" in bold. This happens in table
  cells and list items alike. End the bold before the code and start it again after it, or leave
  the backticks out of the bold phrase when the code holds no markdown characters such as `_` or
  `*`: unquoted, `__init__` renders as a bold "init".
- **Inline code as link text.** Jira keeps the code and drops the link:
  ``[`DECISIONS.md`](https://…)`` came back as plain `DECISIONS.md` in an issue description, with
  no URL anywhere. Write the link text without backticks: `[DECISIONS.md](https://…)`.
- **A bare URL.** Jira stores it as text, not a link: `Draft PR: https://github.com/…/pull/619`
  could not be clicked, and `[org/repo#619](https://github.com/…/pull/619)` became a link. The
  check suggests `[url](url)` because it keeps every word, but that form has not been seen in Jira
  yet, so read the returned `body` after posting one. How Jira converts `<https://…>` is untested,
  so the check asks for the bracket form there too. A URL in inline code or a code block is left
  alone.

The tool refuses one more case outright, so the check leaves it out:

- **A table, heading, horizontal rule or nested blockquote inside a list item.** Jira's format
  cannot hold one there, so the tool refuses the whole post with "Markdown contains structure ADF
  cannot represent". Nothing is posted. End the list before the table and continue it after, and
  turn the item's lead-in sentence into a paragraph above the table.

Read the `body` the tool returns after posting. It is the converted text, so a broken span shows up
there without opening Jira.

## Fixing a posted comment

`addCommentToJiraIssue` with `commentId` replaces that comment's body in place. Use it to correct a
comment rather than posting a second one, which notifies watchers again and leaves both in the
history. The replacement is a new draft: approved wording changes only with fresh approval. A
replacement that only makes the fixes the check requires, keeping every word in the same order, is
the exception, as step 4 above says.

## The acli CLI

`acli` is set up on the work laptop as the fallback when the Atlassian MCP server will not connect.
It logs in with OAuth and keeps the token in the login keychain; never read it out or print it.
Setup is in `tools/jira/README.md`. Tested with acli 1.3.39 on a work ticket:

- **Bodies are ADF, never markdown.** `comment create` and `comment update` store markdown as
  literal text. Write the body as an ADF JSON document (`{"version":1,"type":"doc","content":[…]}`)
  in a file. Headings, nested and numbered lists, tables with a header row, code blocks, and inline
  code as link text all render. ADF does not allow the `code` mark together with any mark except
  `link`, so inline code inside bold is rejected: end the bold before the code.
- **Post from a file, never an argument.** `acli jira workitem comment create --key KEY
  --body-file <file>` reads ADF from the file. Pass one key and never `--jql` or `--filter`, which
  comment on every ticket the query matches; the permission rules refuse those flags.
- **Read every comment with its ID.** `acli jira workitem view KEY --fields comment --json`
  returns all of them. Pipe it through `jq '.fields.comment.comments[] | {id, created, body}'` and
  leave out `body` when only the IDs are needed.
- **`--json` on create leaves out the new comment's ID.** Find it with the read above, as the last
  comment.
- **Fix a posted comment in place.** `acli jira workitem comment update --key KEY --id ID
  --body-adf <file>` replaces the body and notifies nobody unless `--notify` is passed. Use
  `--body-adf`: `update --body-file` takes plain text only. The replacement is a new draft:
  approved wording changes only with fresh approval.
- **A failure says only `unexpected error, trace id: …`.** Run the command again with
  `ACLI_LOG_ENABLED=true ACLI_LOG_FILE=<file>` to log the request and response. The log redacts the
  `Authorization` header; a 401 with `X-Failure-Category: FAILURE_CLIENT_SCOPE_CHECK` means the
  login is an API token rather than OAuth.
