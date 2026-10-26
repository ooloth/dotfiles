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

cmd+g runs the `lazygit` action, which works like the full-screen tmux popup on prefix g. It splits
the focused pane, starts lazygit in the directory of whatever runs there, and zooms lazygit to fill
the tab. Quitting lazygit closes its pane, which ends the zoom. A zoom you had before pressing cmd+g
does not come back, because the split ends it. Lazygit starts through an interactive zsh, because
the login shell Rex uses for commands does not read `.zshrc`, where PATH, EDITOR and
XDG_CONFIG_HOME are set.

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
says why. When there is no `saver.log`, the saver has never started on this machine, and the
warning says to run `u`, then `rex config reload`. To recover an older layout by hand, copy a
file from `history/` over `latest.json`, then restart the Rex server.

`update.bash` runs the saver once, so that its dependencies are in uv's cache for `--offline`.

To remove it, delete `saver.py`, `shell.zsh`, `update.bash`, the tests named below, and the
`start_session_saver` block at the end of `config/init.lua`.

Run its tests with `uv run tools/rex/tests/test_saver.py`. `uv run tools/rex/tests/live_restore.py`
restarts a throwaway Rex server and checks the sessions come back. CI cannot run it, because Rex is
not installed there, so run it by hand after changing the saver.

Run the `init.lua` tests with `uv run tools/rex/tests/test_init.py`. They need `lua` and `luajit`
on the `PATH`, and run under both, because Rex runs its config on its own Lua 5.1.

After changing how ctrl+h/j/k/l reach nvim, here or in `config.nvim`, run `rex config reload`, then
`uv run tools/rex/tests/live_nvim.py`. It opens a throwaway session on your own server with nvim
and a shell side by side, checks that focus moves through nvim's windows and out to the shell and
back, and closes the session. It runs the action through `rex do`, so crossing into another tab is
still checked by pressing the keys in the app.

[006]: https://github.com/ooloth/dotfiles/blob/main/docs/decisions/006-a-python-saver-started-from-rex-init-lua-saves-and-restores-rex-sessions.md
