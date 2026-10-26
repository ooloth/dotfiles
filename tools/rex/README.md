## Installation

For now, manually download macOS application here: https://www.superlogical.com/rex/docs/installation

## Keybindings

`config/init.lua` binds ctrl+h/j/k/l to move focus to the pane on the left, below, above or
right. At a tab's left or right edge, ctrl+h and ctrl+l move on to the previous or next tab,
wrapping from the last tab to the first, and focus the pane on the side just entered, so the
opposite key comes straight back. ctrl+j and ctrl+k wrap at the edge as tmux does.

ctrl+h and ctrl+l run the `focus_pane_or_tab` action. Rex.app chooses which tab it shows, so the
action asks the app to show the new tab, and only an action can ask the app for anything. The app
refuses requests from the CLI unless Remote Control is on in its settings, so run from the CLI, as
in `rex do focus_pane_or_tab direction=right`, the action still moves between panes but stops at a
tab's edge.

When nvim, vim, vi, view or fzf is in the foreground, the key goes to that program instead, the
same way vim-tmux-navigator works in `tools/tmux/config/tmux.conf`. ctrl+j and ctrl+k pass the key
on, and the action sends ctrl+h and ctrl+l on to the program. Neovim keeps the key at its own edge,
because vim-tmux-navigator hands focus on only when `$TMUX` is set, and Rex does not set it.

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

After editing it, run `rex config check`, then `rex config reload`. `rex keymap` lists what loaded.
`config/init.lua` is linked into `~/.config/rex`, so saving it changes your running Rex at once,
and `rex config check` runs it for real: both start the session saver below on your own server. To
try a change to the saver without touching your sessions, run `tests/live_restore.py` instead.

## Sessions after a restart

Rex keeps sessions only in the server's memory, so a reboot or a server restart loses them.
`saver.py` brings them back: each session's tabs, splits and split sizes, labels, working
directories and active tab. Running programs and terminal output do not come back, and nothing but
layouts and directories is written to disk. [Decision 006][006] records why it is a Python script.

`config/init.lua` starts it with `uv run --offline` each time the server loads its config. Only one
copy runs, because each holds a lock in `~/.local/state/rex-restore/`. The first time it runs on a
newly started server, it rebuilds the sessions in `latest.json`. After that it saves each change
within about a second and keeps the last 20 distinct layouts in `history/`.

`shell.zsh` reports each pane's directory to Rex on `cd`, and prints a red warning above the prompt
in Rex panes when the saver has stopped or reports a problem. `saver.log` in the same directory
says why. To recover an older layout by hand, copy a file from `history/` over `latest.json`, then
restart the Rex server.

`update.bash` runs the saver once, so that its dependencies are in uv's cache for `--offline`.

To remove it, delete `saver.py`, `shell.zsh`, `update.bash`, the tests named below, and the
`start_session_saver` block at the end of `config/init.lua`.

Run its tests with `uv run tools/rex/tests/test_saver.py`. `uv run tools/rex/tests/live_restore.py`
restarts a throwaway Rex server and checks the sessions come back. CI cannot run it, because Rex is
not installed there, so run it by hand after changing the saver.

Run the `init.lua` tests with `uv run tools/rex/tests/test_init.py`. They need `lua` and `luajit`
on the `PATH`, and run under both, because Rex runs its config on its own Lua 5.1.

[006]: https://github.com/ooloth/dotfiles/blob/main/docs/decisions/006-a-python-saver-started-from-rex-init-lua-saves-and-restores-rex-sessions.md
