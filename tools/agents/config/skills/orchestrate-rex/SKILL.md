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

## 3. Work the critical path

The item at the top of the order is the focus, along with whatever it waits on. Spend your effort
and the user's attention there first. Later items wait, with two exceptions: work that can run in
parallel without taking the user's attention from the top item, and work whose results the top
item will need. Hold discussion of a later item until it becomes the next most important thing.
That includes its approach and design. A decision made too early can be reversed by what lands
before it, and the code it produces conflicts with that work.

A problem with how the batch is being run, such as a mistake you made, a broken relay, or a
confusing report, comes before the next work item. Resolve it with the user before moving on.

## 4. Move the work

- **Slow external runs** (CI, Spacelift, deploys): sleep for about as long as the run usually
  takes, check once, and repeat until it finishes.
- **Code changes:** start a worker in Rex, one session per ticket, named after the ticket key.
  Each PR branch has its own worktree, and the worker for that PR opens there. A ticket with two
  PRs in one repo gets two worktrees and two tabs. Two agents never work in the same worktree at
  once, and you never edit a worktree a worker owns. Your own scratch work, such as test-merging a
  branch with trunk, goes in a worktree under `mktemp -d` that you remove afterwards. Tell the
  worker the ticket, the PR, what to do, and what to report back. See the `rex` skill for the
  commands. Start each worker with `claude --permission-mode auto`. In the default mode a worker
  stops at a prompt before it loads its first skill, and you can't answer that prompt for the user.
- **Hearing from workers:** don't subscribe to idle notices. Each notice starts a new turn, and a
  run of them buries the user's open questions under several overlapping lists. Instead, only the
  user's messages start your turns. Before every reply, read every worker's pane and every
  external system the table depends on, so the reply covers whatever finished in between. When no
  question to the user is open and work is in flight, stay in the turn: check every few minutes,
  and end the turn only when something needs the user. A message the user sends meanwhile reaches
  you at your next tool call, or at once if they press ctrl-enter. Capture panes with
  `--format=vt` and ignore dim text (`ESC[2m`) on the input line: it is Claude Code's suggested
  next prompt, which nobody typed.
- **Relaying answers:** when the user answers a worker's question in your session, type the answer
  into the worker's pane word for word with `rex send`, then `rex send-key enter`. Keep it on one
  line, since a newline may submit early. Never answer a worker's question yourself. The user's
  settings allow commits, pushes and PR and ticket comments, because the auto-mode classifier can't
  see an approval given in another session and would block them. A rule only reaches sessions
  started after it was added, so restart a running worker with `claude --continue` to pick one up.
  If an approved action is still blocked, tell the user exactly what to type in the worker's tab,
  and don't retry it yourself.
- **Commits:** the worker that made a change runs `/commit` in its own session, where the skill's
  `git status` reads the right repo. Relay the user's commit signal word for word. For a change you
  made yourself, open a Rex tab in that repo running `claude --permission-mode auto "/commit"`
  rather than committing from your session, so its checks don't block you and the user can watch.
- **Side jobs:** a job for a ticket that runs a long time, or that the user may want to watch or
  approve, goes in a new tab in that ticket's session. You or that ticket's worker may open it. A
  bounded question with one answer goes to a subagent instead. When you check a ticket, list its
  session's tabs, so a tab a worker opened shows up in your table.
- **Tabs show the work in flight:** the user reads the sidebar as the list of what is happening.
  Name each worker tab `pr-<number>-<phase>`, where the phase is a word or two saying why the PR
  needs attention now, at the size of `designing`, `implementing`, `reviewing`, `replying`,
  `merging` or `verifying` (after the merge, in dev). Those are examples, not a fixed list. Rename
  the tab when the phase changes. In every sweep, close tabs whose job is finished, such as a
  commit tab after its commit lands or a worker whose PR only waits on the user's merge. Leave
  alone any tab you didn't open.
- **Merges:** merge in the agreed order, and confirm each change works in dev before the next
  merge. The user merges with the "Squash and merge" button on GitHub, so tell them a PR is ready
  to merge and give no command, unless something the button can't do is needed.

## 5. Report

Whenever something changes or needs the user, show the status table. It lists every unfinished
work item in priority order, with the same columns as the first table. A row leaves once its item
is merged and verified in dev. A row joins when an issue comes up or a work item has to be
inserted, such as a failing deploy or a fix to how the batch is run. Build each table from reads
made for that reply, not from earlier ones, since a PR that was clean an hour ago may now conflict
with something that merged. End the reply with one numbered list of what you need from the user.

## 6. Finish

The batch is done when every PR is merged and verified in dev and every ticket is updated. Then
tell the user what caused friction during the run, so this skill can improve.
