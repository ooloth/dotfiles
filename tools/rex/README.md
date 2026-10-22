## Installation

For now, manually download macOS application here: https://www.superlogical.com/rex/docs/installation

## Keybindings

`config/init.lua` binds ctrl+h/j/k/l to move focus to the pane on the left, below, above or
right, wrapping at the edge as tmux does. When nvim, vim, vi, view or fzf is in the foreground, the
key goes to that program instead, the same way vim-tmux-navigator works in
`tools/tmux/config/tmux.conf`. Neovim hands focus back to Rex at its own edge
(`lua/config/plugins/specs/vim-tmux-navigator.lua` in `config.nvim`).

It also binds the cmd keys `tools/ghostty/config/config` sends to tmux to Rex's own actions:

| Key | Action |
| --- | --- |
| cmd+[ / cmd+] | previous / next tab |
| cmd+n / cmd+r | new tab / rename tab |
| cmd+s | change session (picker) |
| cmd+shift+[ / cmd+shift+] | previous / next session |
| cmd+\\ | split right |
| cmd+shift+m | zoom pane (toggle) |

After editing it, run `rex config check`, then `rex config reload`. `rex keymap` lists what loaded.

Run its tests with `uv run tools/rex/tests/test_init.py`. They need `lua` on the `PATH`.
