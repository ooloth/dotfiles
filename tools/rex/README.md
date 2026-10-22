## Installation

For now, manually download macOS application here: https://www.superlogical.com/rex/docs/installation

## Keybindings

`config/init.lua` binds ctrl+h and ctrl+l to move focus to the pane on the left or right, wrapping
at the edge as tmux does. When nvim, vim, vi, view or fzf is in the foreground, the key goes to that
program instead, the same way vim-tmux-navigator works in `tools/tmux/config/tmux.conf`.

After editing it, run `rex config check`, then `rex config reload`. `rex keymap` lists what loaded.

Run its tests with `uv run tools/rex/tests/test_init.py`. They need `lua` on the `PATH`.
