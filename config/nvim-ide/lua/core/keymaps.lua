local set = vim.keymap.set

vim.g.mapleader = ' '

-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- line beginning + end
set({ 'n', 'v' }, '<S-h>', '^', { silent = true })
set({ 'n', 'v' }, '<S-l>', '$', { silent = true })
-- set({ 'n', 'v' }, '$', '<Esc>', { silent = true }) -- practice using L instead

-- clear search highlights
set('n', '<esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })

-- buffer
set('n', '<s-tab>', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
set('n', '<tab>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
set('n', '<leader>`', '<cmd>e#<cr>', { desc = 'Last buffer' }) -- switch to last buffer
-- set('n', '<leader>ff', '<cmd>e#<cr>', { desc = 'Last buffer' }) -- switch to last buffer

-- Close all buffers except the current one (like leader-wo does for windows):
-- https://stackoverflow.com/a/42071865/8802485
set('n', '<leader>fo', '<cmd>%bd|e#<cr>', { desc = 'Only keep this one' })

-- "changes"
set('n', ']c', 'g,', { desc = 'Next change' }) -- go to next change with g;
set('n', '[c', 'g;', { desc = 'Previous change' }) -- go to next change with g;
set('n', 'g;', 'g,', { desc = 'Next change' }) -- go to next change with g;
set('n', 'g:', 'g;', { desc = 'Previous change' }) -- go to previous change with g;

-- "debug" (see debug.lua)
-- "explorer" (see neo-tree.lua)

-- "git" (see git.lua)
-- set({ 'n', 'v' }, '<leader>gg', '<cmd>FloatermNew lazygit<cr>', { desc = 'Lazygit' })

-- "help" (see telescope.lua)
-- "i"
-- "jumps" (see telescope.lua)
-- "keymaps" (see telescope.lua)
-- "lazy" / "LSP" (see lsp.lua)
-- "mason" (see lsp.lua)
-- "null-ls" (see lsp.lua)

-- "open"
set('n', 'gl', '<cmd>lopen<cr>', { desc = 'Location list' })
set('n', 'gq', '<cmd>copen<cr>', { desc = 'Quickfix list' })
set('n', '<leader>ol', '<cmd>lopen<cr>', { desc = 'Location list' }) -- use ]l + [l to navigate
set('n', '<leader>oq', '<cmd>copen<cr>', { desc = 'Quickfix list' }) -- use ]q + [q to navigate
set('n', '<leader>on', ':ene <BAR> startinsert<cr>', { desc = 'New file' })
-- '<leader>ot' = 'Terminal' (see vim-floaterm.lua)

-- "pin" (see mini-bufremove.lua + bufferline.lua)
-- "quit"
-- "replace" (see spectre.lua + lsp.lua)

-- "save"
set('n', '<leader><space>', '<cmd>w<cr>', { desc = 'Save' })

-- -- "tab"
-- set('n', '<leader>tt', '<cmd>tabnew<cr>', { desc = 'New tab' })
-- set('n', '<leader>tf', '<cmd>tabfirst<cr>', { desc = 'First tab' })
-- set('n', '<leader>tl', '<cmd>tablast<cr>', { desc = 'Last tab' })
-- set('n', '<leader>t]', '<cmd>tabnext<cr>', { desc = 'Next tab' })
-- set('n', '<leader>tn', '<cmd>tabnext<cr>', { desc = 'Next tab' })
-- set('n', '<leader>t[', '<cmd>tabprevious<cr>', { desc = 'Previous tab' })
-- set('n', '<leader>tp', '<cmd>tabprevious<cr>', { desc = 'Previous tab' })
-- set('n', '<leader>tc', '<cmd>tabclose<cr>', { desc = 'Close tab' })
-- set('n', ']t', '<cmd>tabnext<cr>', { desc = 'Next tab' })
-- set('n', '[t', '<cmd>tabprevious<cr>', { desc = 'Next tab' })
-- del('n', '<leader><tab><tab>')
-- del('n', '<leader><tab>]')
-- del('n', '<leader><tab>[')
-- del('n', '<leader><tab>f')
-- del('n', '<leader><tab>l')
-- del('n', '<leader><tab>d')

-- "ui"
-- "v"

-- "window"
-- TODO: add mappings for all <c-w> commands?
set('n', '<leader>\\', '<c-w>v', { desc = 'Split right' })
set('n', '<leader>w\\', '<c-w>v', { desc = 'Split right' })
set('n', '<leader>-', '<c-w>v', { desc = 'Split below' })
set('n', '<leader>w-', '<c-w>v', { desc = 'Split below' })
set('n', '<leader>=', '<c-w>=', { desc = 'Resize equally' })
set('n', '<leader>w=', '<c-w>=', { desc = 'Resize equally' })
set('n', '<leader>[', '<cmd>vertical resize -3<cr>', { desc = 'Reduce size' })
set('n', '<leader>w[', '<cmd>vertical resize -3<cr>', { desc = 'Reduce size' })
set('n', '<leader>]', '<cmd>vertical resize +3<cr>', { desc = 'Increase size' })
set('n', '<leader>w]', '<cmd>vertical resize +3<cr>', { desc = 'Increase size' })
set('n', '<leader>wc', '<c-w>c', { desc = 'Close' })
set('n', '<leader>wh', '<c-w>h', { desc = 'Go left one window' })
set('n', '<leader>wj', '<c-w>j', { desc = 'Go down one window' })
set('n', '<leader>wk', '<c-w>k', { desc = 'Go up one window' })
set('n', '<leader>wl', '<c-w>l', { desc = 'Go right one window' })
-- "leader-wm" = toggle maximize window (see vim-maximizer.lua}
set('n', '<leader>wo', '<c-w>o', { desc = 'Only keep this one' })
set('n', '<leader>wt', '<cmd>tab split<cr>', { desc = 'Open in new tab' })
-- "leader-ww" = pick window (see nvim-window-picker.lua)

-- -- overwrite lazyvim mappings with vim-kitty-navigator mappings
-- -- see: https://github.com/christoomey/vim-tmux-navigator/blob/master/plugin/tmux_navigator.vim
-- vim.cmd([[
--   noremap <silent> <c-h> :<C-U>KittyNavigateLeft<cr>
--   noremap <silent> <c-j> :<C-U>KittyNavigateDown<cr>
--   noremap <silent> <c-k> :<C-U>KittyNavigateUp<cr>
--   noremap <silent> <c-l> :<C-U>KittyNavigateRight<cr>
--   noremap <silent> <c-\> :<C-U>KittyNavigatePrevious<cr>
-- ]])

-- overwrite lazyvim mappings with vim-tmux-navigator mappings
-- see: https://github.com/christoomey/vim-tmux-navigator/blob/master/plugin/tmux_navigator.vim
vim.cmd([[
  noremap <silent> <c-h> :<C-U>TmuxNavigateLeft<cr>
  noremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
  noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
  noremap <silent> <c-l> :<C-U>TmuxNavigateRight<cr>
  noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>
]])

-- "x" ("diagnostics")
-- "y"
-- "z"
