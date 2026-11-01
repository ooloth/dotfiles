## Installation

For now, manually download macOS application here: https://www.superlogical.com/rex/docs/installation

## Keybindings

`config/init.lua` binds ctrl+h/j/k/l to move focus to the nvim window, pane or tab on the left,
below, above or right. At a tab's left or right edge, ctrl+h and ctrl+l move on to the previous or
next tab, wrapping from the last tab to the first, and focus the pane on the side just entered, so
the opposite key comes straight back. ctrl+j and ctrl+k wrap at the edge as tmux does.

All four keys run the `focus_pane_or_tab` action. Rex.app chooses which tab it shows, so the action
asks the app to show the new tab, and only an action can ask the app for anything. The app refuses
requests from the CLI unless Remote Control is on in its settings, so run from the CLI, as in
`rex do focus_pane_or_tab direction=right`, the action still moves between panes but stops at a
tab's edge.

When nvim is in the foreground, the action first asks it to move between its own windows, over a
socket at `~/.local/state/rex/nvim/<block id>.sock`, which nvim opens when it starts in a Rex pane
(`lua/config/rex.lua` in `config.nvim`). nvim answers that it moved, that it's at its edge, or that
it's busy typing text or at a prompt. Rex moves only at the edge, and otherwise sends the key on to
nvim. Landing in a pane that runs nvim, Rex asks nvim to focus its window on the side Rex came in
from. vim, vi, view and fzf have no socket, so they always get the key, the same way
vim-tmux-navigator works in `tools/tmux/config/tmux.conf`.

When something goes wrong, such as an nvim that doesn't answer within 0.5 s, the action writes why
to `~/.local/state/rex/focus.log`, because `rex.log` output appears in neither the server log nor
`rex events`. Past 1 MB the log moves to `focus.log.1`.

It also binds the cmd keys `tools/ghostty/config/config` sends to tmux to Rex's own actions, plus
cmd+shift+r to rename the session:

| Key | Action |
| --- | --- |
| cmd+[ / cmd+] | previous / next tab |
| cmd+n / cmd+r | new tab / rename tab |
| cmd+s | change session (picker) |
| cmd+shift+r | rename session |
| cmd+shift+[ / cmd+shift+] | previous / next session |
| cmd+\\ | split right |
| cmd+shift+m | zoom pane (toggle) |

cmd+g runs the `lazygit` action, which works like the tmux popup on prefix g. It opens lazygit in a
floating layer over the tab, inset 2.5% on each side, in the directory of whatever runs in the
focused pane. A new float would otherwise start in the home directory. Quitting lazygit closes the
float. Two things in current Rex differ from the tmux popup: a float that takes focus ends any zoom,
which an open Rex bug ("Focused floating layer clears pane zoom, and closing it doesn't restore
it") reports, and after the float closes Rex focuses the tab's last pane rather than the one cmd+g
was pressed in. Lazygit starts through an interactive zsh, because the login shell Rex uses for
commands does not read `.zshrc`, where PATH, EDITOR and XDG_CONFIG_HOME are set.

After editing it, run `rex config check`, then `rex config reload`. `rex keymap` lists what loaded.
`config/init.lua` is linked into `~/.config/rex`, so saving it changes your running Rex at once.

Run the `init.lua` tests with `uv run tools/rex/tests/test_init.py`. They need `luajit` on
the `PATH`, because Rex runs its config on its own Lua 5.1 and LuaJIT implements the same version.
So syntax and libraries from later Luas that LuaJIT also lacks, such as `&`, `utf8` and
`table.unpack`, fail the tests as they would in Rex. LuaJIT accepts some things plain Lua 5.1 does
not, such as `1LL`, the `bit` library and `goto`, so those pass the tests and may still fail in Rex.

After changing how ctrl+h/j/k/l reach nvim, here or in `config.nvim`, run `rex config reload`, then
`uv run tools/rex/tests/live_nvim.py`. It opens a throwaway session on your own server with nvim
and a shell side by side, checks that focus moves through nvim's windows and out to the shell and
back, and closes the session. It runs the action through `rex do`, so crossing into another tab is
still checked by pressing the keys in the app.

## Sessions after a restart

The Rex server restores its sessions itself when it starts again, after a reboot or a server
restart. Each session comes back with its tabs, splits, floating layers, labels and active tab, and
each pane opens a new shell in the directory its program was in. Running programs and scrollback do
not come back. Each server keeps this in `servers/<id>/snapshot/` under
`~/Library/Application Support/rex/`, next to its log, `servers/<id>.log`. After a restart that log
has a `restored saved sessions` line, and non-zero `skipped_sessions` or `skipped_blocks` counts on
it mean something did not come back. `config/init.lua` starts nothing of its own to save or
restore sessions, because a second restorer would bring every session back twice.
[Decision 009][009] records why.

[009]: https://github.com/ooloth/dotfiles/blob/main/docs/decisions/009-rexs-built-in-session-restore-replaces-the-saver.md

## Claude Code in a new tab

`claude-tab.bash` opens a Rex tab running Claude Code through `tools/claude/cc.bash`, so the tab
gets this machine's permission mode and the repo's related folders, as `cc` would give them:

```sh
bash "$DOTFILES/tools/rex/claude-tab.bash" [-s <session>] '<tab name>' <directory> [claude arguments]
```

The tab opens in the Rex session labelled `Workers` unless `-s` names another session. When no
`Workers` session exists, the launcher creates one with this tab as its first window. Rex's JSON
for the new tab goes to stdout, with its pane at `.block_ids[0]`. Capture that pane with
`rex capture -s Workers -b <pane>`, or with the session passed to `-s`, because Rex looks for a pane
only in the caller's own session otherwise. Tab names start with a word, not an emoji. Agents start
every Claude tab this way, as the `use-rex` skill says, so no skill names a permission mode itself.
Tests: `uv run tools/rex/tests/test_claude_tab.py`.
