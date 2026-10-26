---
name: use-rex
description: Rex gotchas, and the one way to start a Claude Code session in a Rex tab. Read before every rex command, because a tab started the wrong way stalls at a permission prompt nobody sees, and a failed step in a chained command can leave you reading your own pane. Re-invoke each time.
allowed-tools: [Bash, Read]
---

Read the `rex` skill's guide for the commands themselves. This skill holds what that guide doesn't
say.

## Start Claude in a tab only through the launcher

```sh
bash "$DOTFILES/tools/rex/claude-tab.bash" [-s <session>] '<tab name>' <directory> [claude arguments]
```

It runs Claude through `tools/claude/cc.bash`, which picks this machine's permission mode and adds
the repo's related folders. Never start `claude` in a tab yourself, with or without
`--permission-mode`. The right mode differs between machines, and a session started in the default
mode stops at its first skill prompt, where nobody is watching.

The tab opens in `$REX_SESSION` unless `-s` names another session. The launcher prints Rex's JSON,
and `.block_ids[0]` is the pane to capture.

## Gotchas

- **Don't chain a close and an open with `&&`.** If the user already closed the tab, `rex window
  close` fails and the new tab never opens. List the tabs first, or run the two separately.
- **Read IDs with `jq -e`.** `jq -r` turns a missing ID into an empty string, and
  `rex capture -b ""` captures your own pane instead of failing.
