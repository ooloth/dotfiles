---
name: use-rex
description: Rex gotchas, and the one way to start a Claude Code session in a Rex tab. Read before every rex command, because a tab started the wrong way stalls at a permission prompt nobody sees, and a failed step in a chained command can leave you reading your own pane. Re-invoke each time.
allowed-tools: [Bash, Read]
---

Read the `rex` skill's guide for the commands themselves. This skill holds what that guide doesn't
say.

## Start Claude in a tab only through the launcher

```sh
bash ~/Repos/ooloth/dotfiles/tools/rex/claude-tab.bash [-s <session>] '<tab name>' <directory> [claude arguments]
```

It runs Claude through `tools/claude/cc.bash`, which picks this machine's permission mode and adds
the repo's related folders. Never start `claude` in a tab yourself, with or without
`--permission-mode`. The right mode differs between machines, and a session started in the default
mode stops at its first skill prompt, where nobody is watching.

A tab nobody will watch work, such as one `monitor-prs` or `orchestrate-rex` opens, passes
`--unattended` as its first Claude argument, before the prompt. `cc.bash` then starts it in auto
mode on every machine, never in bypass mode.

The tab opens in the session for its directory's repository, labelled `Workers (<repo>)`, where
`<repo>` is the name the repository's `origin` remote ends in, so every checkout and worktree of a
repository shares one session whatever its folder is called. A directory outside any repository, or
a repository with no `origin`, uses `Workers`, and `-s` names another session instead. When the
session doesn't exist, the launcher creates it with this tab as its first window. The launcher
prints Rex's JSON for the new tab: `.block_ids[0]` is its pane and `.session_id` its session. Rex
looks for a pane only in your own session unless `-s` names another, so capture it with
`rex capture -s <session_id> -b <pane>`.

A tab's name says what is happening in it: `<subject> (<person>): <activity>`. The subject is what
the tab works on, such as `PR 123`, `Issue 412` or `ENG-45`. The person is the login of whoever
wrote the subject: the PR's or issue's author, or your user's login for a ticket with no PR yet.
Leave out the parentheses when no person wrote it, as in `CI test-suite: investigate`. The activity
is the skill the tab runs, such as `review-code`, so other skills can tell from the label alone that
a PR is already being handled. A tab that runs no skill names its activity in one plain word, such
as `investigate`, `lazygit` or `diff`.

Tab names start with a word, never an emoji: `PR 123 (alice): review-code`, not
`👀 PR 123 (alice): review-code`.

## Gotchas

- **Don't chain a close and an open with `&&`.** If the user already closed the tab, `rex window
  close` fails and the new tab never opens. List the tabs first, or run the two separately.
- **Read IDs with `jq -e`.** `jq -r` turns a missing ID into an empty string, and
  `rex capture -b ""` captures your own pane instead of failing.
