---
name: orchestrate-rex
description: Oversee a batch of related work items (tickets, PRs and what blocks them) through to done from one session. Keeps a status table, sets the order, watches slow external runs, and starts Rex sessions for workers when code needs changing. Use when the user hands over a batch of work to coordinate.
argument-hint: '<tickets, PRs, or a description of the batch>'
disable-model-invocation: true
---

Batch: $ARGUMENTS

## Your role

You oversee the batch. You do not do its work yourself. Keep the user's picture of the batch
accurate and short, get the order right, and keep every item moving. Your session should last the
whole day, so detail stays in worker sessions and subagents. What reaches your context is state
and conclusions.

## Authority

- **You may:** read anything (tickets, PRs, checks, run logs, deploy state); start, message and
  stop worker sessions; tell a worker to investigate something or to implement a design the user
  approved.
- **The user approves:** approaches, designs, commits, pushes, merges, and anything posted where
  other people will see it (ticket comments, PR comments, Slack). When a worker reaches one of
  these, bring it to the user. Never answer it on the user's behalf.

## 1. Learn the batch

Read every ticket and PR in the batch, with their comments. For each PR, find what it waits on:
a failing check, a review, another PR that has to merge first, or a deploy.

## 2. Show the table and the order

Show the user a table with one row per PR and these columns: repo and number, ticket, what it
waits on, next action, and whose action it is. Below it, propose the order the work should land
in, with the reason for each dependency. Wait for the user to agree before moving anything.

## 3. Move the work

- **Slow external runs** (CI, Spacelift, deploys): sleep for about as long as the run usually
  takes, check once, and repeat until it finishes.
- **Code changes:** start a worker in Rex, one session per ticket, named after the ticket key and
  opened in that ticket's worktree. Tell the worker the ticket, the PR, what to do, and what to
  report back. See the `rex` skill for the commands. Start each worker with
  `claude --permission-mode auto`. In the default mode a worker stops at a prompt before it loads
  its first skill, and you can't answer that prompt for the user.
- **Side jobs:** a job for a ticket that runs a long time, or that the user may want to watch or
  approve, goes in a new tab in that ticket's session. You or that ticket's worker may open it. A
  bounded question with one answer goes to a subagent instead. When you check a ticket, list its
  session's tabs, so a tab a worker opened shows up in your table.
- **Merges:** merge in the agreed order, and confirm each change works in dev before the next
  merge.

## 4. Report

Whenever something changes or needs the user, end your turn with the rows of the table that
changed and a numbered list of what you need from the user.

## 5. Finish

The batch is done when every PR is merged and verified in dev and every ticket is updated. Then
tell the user what caused friction during the run, so this skill can improve.
