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

A PR's feedback lives in three places, and each needs its own read: the body of each review
(`pulls/<n>/reviews`), the inline comments (`pulls/<n>/comments`), and the conversation comments,
bots included (`gh pr view <n> --json comments`). An approval often carries its findings in the
review body alone. Any feedback in any of the three, approved or not, means the PR waits on its
worker running `/review-pr-comments-converge` (see "Review feedback" below). Don't fix, dismiss
or answer the comments in its place, and don't call the PR ready to merge. Judging what the skill
then reports is a separate step, and it is yours (see "Judge every finding" below).

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

An item is one PR. When the user groups several, such as one author's PRs, the group decides where
they sit in the order, and each PR in it is still its own item, discussed on its own.

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
  line, since a newline may submit early. `rex send` can drop the start of a long message, so an
  instruction longer than a line or two goes in a file in your scratch directory, and the text you
  send is one line telling the worker to read that file and follow it. Never answer a worker's
  question yourself. The user's settings allow commits, pushes and PR and ticket comments, because
  the auto-mode classifier can't see an approval given in another session and would block them. A
  rule only reaches sessions started after it was added, so restart a running worker with
  `claude --continue` to pick one up. If an approved action is still blocked, tell the user exactly
  what to type in the worker's tab, and don't retry it yourself. A question from the worker of a
  later item waits until that item is at the top. The same holds for a decision the user makes in
  your session about a worker's work: quote it rather than restating it.
- **Review feedback:** when a PR has review comments to assess or answer, tell its worker to run
  `/review-pr-comments-converge <pr-number>` rather than handle the comments one by one, so a
  single skill defines how feedback is assessed, fixed and answered. Relay the skill's escalations
  and proposed replies to the user, and leave its full report in the worker's tab.
- **Skill-shaped writing:** an approach or design comment, a PR or ticket description, review
  replies, a review posted on someone else's PR, and a commit message are each written under a
  skill (discuss, design, write-pr-description, write-ticket-description,
  review-pr-comments-converge, review-code, commit). A brief to the worker who writes one names the
  skill and passes on the user's decisions in the user's own words. It says nothing about the
  shape, such as body or inline comments, line breaks or length, because the skill owns that; when
  the user's words seem to call for a shape the skill doesn't, ask the user before briefing. When a
  worker produced one under its skill, post it as written. The only edits you make are the ones the
  destination forces, such as moving code out of bold for Jira, and you show the user each one.
  Never condense, reorder or restyle it. When you draft one yourself, invoke its skill first and
  follow it, as a worker would.
- **Review before a PR opens:** after a worker pushes a draft PR, and before it is marked ready or
  anyone is asked to review it, review it with review-code. Create a detached worktree at the PR's
  head (`git worktree add --detach "$(mktemp -d)/review-<n>" <head-sha>`) and open a new tab there
  named `pr-<n>-review-code`, running `claude --permission-mode auto` with a prompt that says:
  - This is the author's own review before the PR opens, and no teammate will see the report. So
    every finding is something to fix before opening, or a question for the user. Don't grade
    findings as optional for a later reviewer, and don't suggest leaving one for the team review.
  - Show the full report in this tab, and also write the same report to a file you name.
  - Post nothing, edit nothing, commit nothing.

  If the review asks whether to post, pass that question to the user. Read the file, check the
  claims that decide something, and give the user a short summary that says what you checked.
  Send every finding the user accepts to the PR's worker. When the change touches auth,
  credentials, migrations or infrastructure, also run review-adversarial the same way, as a second
  review in its own tab and worktree, named `pr-<n>-review-adversarial`. Remove each review
  worktree once its tab is closed.
- **Judge every finding:** a reviewer's findings, and a worker's fixes and escalations, reach the
  user only with your own verdict on each one. The reviewer has already filtered its subagents'
  findings, and you are the second reader of its judgment. For each finding, open the code it
  cites and decide whether the claim is true, whether it matters at this PR's scope, and whether
  the proposed fix is the right size. Then say plainly whether you agree, and why, and say when
  you would take a smaller fix, a different one, or none. Where the reviewer and the worker
  disagree or overlap, reconcile them into one recommendation. The user should be able to accept
  your recommendations without reading the report. Disagreeing with a reviewer is part of the job:
  a list you relay without a verdict leaves the user to do the judging.
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
with something that merged.

End the reply with one numbered list of what you need from the user, about the top item in the
order and nothing below it. The table shows the rest, and that is enough. A
question about a later item switches the user's attention away from the work being finished, and
its answer rests on assumptions the earlier items may still overturn. Leave it until the item
rises to the top, when fewer assumptions stand under it and the question is easier to answer. A
problem with how the batch is run always comes first (see section 3).

A reply discusses one PR: the top row. When the top item waits on agents or external runs and
needs nothing from the user, say so and keep working; move to the next item only when the top one
leaves the table or waits only on someone other than the user, such as its author. Work finished
early on a later item, including a review report or a worker's question, stays in its tab until
that item reaches the top. The table can say it is ready, and nothing more.

Number each question, and letter the parts of a question that has several (a, b, c), so the
user can answer "2b yes" without retyping it. Put your recommendation beside each part, so a
plain "yes" accepts it.

This session is the only thing the user reads, so each reply carries everything its decisions
rest on. A question refers only to something stated in that same reply, never to a report in a
worker's tab or a file. A side effect the user is asked to approve is shown in full: the exact
text, where it goes, and as what (for example, an approving review on PR 281).

A summary of a review gives every finding its own bullet, dropped findings included, labelled
with the PR and the review's own number (`280-1`, `280-2`), so the user can match it to the
report. Each bullet states the finding in a sentence and the review's call on it (block, raise,
drop). Every further point under a finding, such as an option, a caveat or a sub-question, is a
nested bullet with a letter (`280-1a`, `280-1b`). Questions refer to these labels.

## 6. Finish

The batch is done when every PR is merged and verified in dev and every ticket is updated. Then
tell the user what caused friction during the run, so this skill can improve.

## 7. Improve this skill

You write every change to this skill yourself, from your own experience running it. Never hand
the writing to a worker: a worker hasn't run the batch, and the user depends on you to fix how it
is run. When the user agrees to a change, make it straight away, before the next work item. Only
the commit is delegated, through a Rex tab running `/commit`, once the user gives the signal.
