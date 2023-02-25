-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local set = vim.keymap.set
local del = vim.keymap.del

-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)
set('n', 'g;', 'g,') -- go to next change with g;
set('n', 'g:', 'g;') -- go to previous change with g;

-- "actions" (see lsp.lua)

-- "buffer"
set('n', '<tab>', '<cmd>bnext<cr>') -- go to next buffer
set('n', '<s-tab>', '<cmd>bprev<cr>') -- go to previous buffer
set('n', '<leader>`', '<cmd>e #<cr>', { desc = 'Last buffer' }) -- switch to last buffer
set('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Last buffer' }) -- switch to last buffer

-- "c"?

-- "diagnostics" (see lsp.lua)
-- "explorer" (see neo-tree.lua)

del('n', '<leader>st')
-- "find" (see telescope.lua)

-- "git" (see git.lua)
set({ 'n', 'v' }, '<leader>gg', '<cmd>FloatermNew lazygit<cr>', { desc = 'Lazygit' })
del('n', '<leader>gG')

-- "help" (see telescope.lua)
-- "inspect" (for debugging)
-- "jumps" (see telescope.lua)
-- "keymaps" (see telescope.lua)
-- "lazy" + "Lsp" (see lsp.lua)
-- "mason" (see lsp.lua)
-- "null-ls" (see lsp.lua)

-- "open"
set('n', '<leader>ol', '<cmd>lopen<cr>', { desc = 'Location list' }) -- use ]l + [l to navigate
set('n', 'gl', '<cmd>lopen<cr>', { desc = 'Location list' })
set('n', '<leader>oq', '<cmd>copen<cr>', { desc = 'Quickfix list' }) -- use ]q + [q to navigate
set('n', 'gq', '<cmd>copen<cr>', { desc = 'Quickfix list' })
-- '<leader>ot' = 'Terminal' (see vim-floaterm.lua)
del('n', '<leader>ft')
del('n', '<leader>fT')

-- "p"

-- "r"

-- "save"
set('n', '<leader>s', '<cmd>w<cr>', { desc = 'Save' })

-- "tabs"

-- "u" ("ui"? "undo list"?)

-- "v" ("view"?)

-- "window"
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
set('n', '<leader>wd', '<c-w>c', { desc = 'Delete' })
-- m = { '<cmd>MaximizerToggle<cr>', 'maximize / unmaximize' }, -- maximize split OR restore previous split layout (with vim-maximizer}
set('n', '<leader>wo', '<c-w>o', { desc = 'Only keep this one' })
set('n', '<leader>ww', '<cmd>w<cr>', { desc = 'Write' })
del('n', '<leader>|')
del('n', '<leader>w|')

-- overwrite lazyvim mappings with vim-tmux-navigator mappings
-- see: https://github.com/christoomey/vim-tmux-navigator/blob/master/plugin/tmux_navigator.vim
vim.cmd([[
  noremap <silent> <c-h> :<C-U>TmuxNavigateLeft<cr>
  noremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
  noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
  noremap <silent> <c-l> :<C-U>TmuxNavigateRight<cr>
  noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>
]])

-- "x" ("close buffer?", "problems?", "quickfix + subcommands for navigating it?")

-- "y"

-- "z" ("lazy"? "undo list"?)
