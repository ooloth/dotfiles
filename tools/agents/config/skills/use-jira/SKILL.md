---
name: use-jira
description: Jira gotchas for the Atlassian MCP tools and the acli and jira CLIs. Covers the cloud ID that works, reads that silently omit comments, fields and paging that make responses too large or incomplete, and markdown that Jira's conversion breaks in posted comments and descriptions. Read before every Jira tool call, reads included, because a bad post notifies watchers and stays in the history. Re-invoke each time.
---

## Cloud ID

Pass `59cf1bda-d77b-4f71-9550-c99e58dd7572` as `cloudId`. It is the `recursion.atlassian.net`
site. The hostname `recursionpharma.atlassian.net` belongs to a different site this account is not
granted, and the call fails with "isn't explicitly granted by the user". Call
`getAccessibleAtlassianResources` only when that ID is refused.

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
does not survive:

- **Inline code inside bold.** Jira ends the bold where the code starts:
  `**New client in `x` (chosen)**` renders with only "New client in" in bold. This happens in table
  cells and list items alike. Leave the backticks out of a bold phrase, or put the code after the
  bold ends.
- **Inline code as link text.** Jira keeps the code and drops the link:
  ``[`DECISIONS.md`](https://…)`` came back as plain `DECISIONS.md` in an issue description, with
  no URL anywhere. Write the link text without backticks: `[DECISIONS.md](https://…)`.
- **A table, heading, horizontal rule or nested blockquote inside a list item.** Jira's format
  cannot hold one there, so the tool refuses the whole post with "Markdown contains structure ADF
  cannot represent". Nothing is posted. End the list before the table and continue it after, and
  turn the item's lead-in sentence into a paragraph above the table.

Read the `body` the tool returns after posting. It is the converted text, so a broken span shows up
there without opening Jira.

## Fixing a posted comment

`addCommentToJiraIssue` with `commentId` replaces that comment's body in place. Use it to correct a
comment rather than posting a second one, which notifies watchers again and leaves both in the
history. The replacement is a new draft: approved wording changes only with fresh approval.

## The acli CLI

`acli` is set up on the work laptop as the fallback when the Atlassian MCP server will not connect.
It logs in with OAuth and keeps the token in the login keychain; never read it out or print it.
Setup is in `tools/jira/README.md`. Tested with acli 1.3.39 on CENG-349:

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

## The jira CLI

`jira` (jira-cli) is the second fallback until it is removed
([#196](https://github.com/ooloth/dotfiles/issues/196)). Use it only when acli fails. Its token is
in the login keychain and jira-cli reads it there; never read it out, print it or export it. Setup
is in `tools/jira/README.md`.

- **Reads show one comment.** `jira issue view KEY --plain` prints the latest comment only. Pass
  `--comments 50` (or more than the ticket has) when the plan is what you came for.
- **Post from a file, never an argument.** `jira issue comment add KEY --template <file>
  --no-input` reads the body from the file and skips the editor prompt. A body passed as an argument
  goes through the shell, and a positional body silently wins over `--template`.
- **A posted comment cannot be fixed from the CLI.** jira-cli has `comment add` and nothing else, so
  a mistake stays until someone edits it in the web UI. Validate the body before posting, harder
  than for the MCP tool.
- **Markdown survives only in its simplest shapes.** jira-cli converts the body to Jira wiki markup
  (blackfriday-confluence, posted to API v2). Tested on CENG-349: paragraphs, inline code, bold,
  links (including code as link text) and a flat bullet list survive. A heading runs into the
  paragraph above as literal `h2.` text, a nested bullet and a numbered list after a bullet list
  become literal `**` and `#` lines, a table keeps its `|-|` separator as a row of dashes with no
  header row, and a code block lands inside a stray bullet tagged as Java. Post only paragraphs and
  flat lists through the CLI, and keep the inline code, bold and links inside them: they survive,
  and they make a long comment far faster to skim. Read the comment back with
  `jira issue view KEY --comments 1 --raw`, since `--plain` re-renders it and hides some breakage.
