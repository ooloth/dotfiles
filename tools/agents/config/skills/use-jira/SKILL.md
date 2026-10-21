---
name: use-jira
description: Jira gotchas for the Atlassian MCP tools. Covers the cloud ID that works, reads that silently omit comments, fields and paging that make responses too large or incomplete, and markdown that Jira's conversion breaks in posted comments and descriptions. Read before every Jira tool call, reads included, because a bad post notifies watchers and stays in the history. Re-invoke each time.
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
