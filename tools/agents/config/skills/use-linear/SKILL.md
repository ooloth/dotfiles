---
name: use-linear
description: Reference for using Linear via MCP tools. Use when creating, updating, or querying Linear issues, projects, teams, or comments.
model: haiku
effort: low
---

## Workspace

- **Team:** Michael (ID: `82e423ff-8463-4803-9822-07bcf57c8a08`)
- No need to call `list_teams` — pass `"Michael"` as the team name directly.

## Loading Tools (required before every call)

Linear MCP tools are deferred. Fetch schemas before calling:

```
ToolSearch: select:mcp__linear-server__save_issue,mcp__linear-server__list_issues
```

Use `select:<tool1>,<tool2>` with exactly the tools you need for the task.

## Common Workflows

### Create an issue

Always invoke `write-ticket-description` skill first, then:

```
mcp__linear-server__save_issue
  team: "Michael"
  title: "..."
  description: "..."   # Markdown; use real newlines, not \n
  priority: 3          # see scale below
  state: "Backlog"     # optional
```

### Update an issue

```
mcp__linear-server__save_issue
  id: "MU-5"           # issue identifier
  title: "..."         # only include fields you want to change
  state: "In Progress"
```

### List issues

```
mcp__linear-server__list_issues
  team: "Michael"
  limit: 25
```

### Get a single issue

```
mcp__linear-server__get_issue
  id: "MU-5"
```

### Add a comment

```
mcp__linear-server__save_comment
  issueId: "MU-5"
  body: "..."
```

## Priority Scale

| Value | Label   |
| ----- | ------- |
| 0     | No priority |
| 1     | Urgent  |
| 2     | High    |
| 3     | Medium  |
| 4     | Low     |

## Full Tool List

| Tool | Purpose |
| ---- | ------- |
| `save_issue` | Create or update an issue |
| `get_issue` | Fetch a single issue by ID |
| `list_issues` | List/filter issues |
| `get_issue_status` | Get status of an issue |
| `list_issue_statuses` | List available statuses for a team |
| `save_comment` | Create or update a comment |
| `list_comments` | List comments on an issue |
| `delete_comment` | Delete a comment |
| `get_project` | Fetch a project |
| `list_projects` | List projects |
| `save_project` | Create or update a project |
| `get_team` | Fetch team details |
| `list_teams` | List all teams (not needed — team is "Michael") |
| `get_user` | Fetch a user |
| `list_users` | List workspace members |
| `list_issue_labels` | List labels |
| `create_issue_label` | Create a label |
| `list_cycles` | List sprint cycles |
| `get_milestone` | Fetch a milestone |
| `list_milestones` | List milestones |
| `save_milestone` | Create or update a milestone |
| `list_documents` | List documents |
| `get_document` | Fetch a document |
| `save_document` | Create or update a document |
| `get_diff` / `list_diffs` | PR diff threads linked to issues |
| `search_documentation` | Search Linear's help docs |
| `extract_images` | Extract images from an issue or comment |
