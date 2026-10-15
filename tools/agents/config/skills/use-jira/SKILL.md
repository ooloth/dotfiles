---
name: use-jira
description: Jira gotchas for the Atlassian MCP tools. Covers the cloud ID that works, reads that silently omit comments, and markdown that Jira's conversion breaks in posted comments and descriptions. Read before every Jira tool call, reads included, because a bad post notifies watchers and stays in the history. Re-invoke each time.
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

## Markdown that Jira's conversion breaks

Posting with `contentFormat: "markdown"` converts the body to Jira's own format, and some markdown
does not survive:

- **Inline code inside bold.** Jira ends the bold where the code starts:
  `**New client in `x` (chosen)**` renders with only "New client in" in bold. This happens in table
  cells and list items alike. Leave the backticks out of a bold phrase, or put the code after the
  bold ends.

Read the `body` the tool returns after posting. It is the converted text, so a broken span shows up
there without opening Jira.

## Fixing a posted comment

`addCommentToJiraIssue` with `commentId` replaces that comment's body in place. Use it to correct a
comment rather than posting a second one, which notifies watchers again and leaves both in the
history. The replacement is a new draft: approved wording changes only with fresh approval.
