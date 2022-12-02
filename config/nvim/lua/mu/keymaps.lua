vim.g.mapleader = ' '

--------------------
-- NON-LEADER KEY --
--------------------

-- command mode
vim.keymap.set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :

-- navigation
vim.keymap.set('n', '<TAB>', ':bnext<CR>') -- go to next buffer
vim.keymap.set('n', '<S-TAB>', ':bprev<CR>') -- go to previous buffer
vim.keymap.set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-------------
-- PLUGINS --
-------------

----------------
-- LEADER KEY --
----------------

-- symbols
vim.keymap.set('n', '<leader>+', '<C-a>') -- increment number under cursor
vim.keymap.set('n', '<leader>-', '<C-x>') -- decrement number under cursor

-- e (explore)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>') -- view project file tree

-- f (find)
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>') -- find open buffers
vim.keymap.set('n', '<leader>fc', '<cmd>Telescope grep_string<CR>') -- find string under cursor in cwd
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope git_files<CR>') -- fuzzy-find files in cwd (respects .gitignore)
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>') -- find available help tags
vim.keymap.set('n', '<leader>fs', '<cmd>Telescope live_grep<CR>') -- fuzzy-find string in cwd

-- g (git)
vim.keymap.set('n', '<leader>gb', '<cmd>Telescope git_branches<CR>') -- list branches (use <CR> to checkout)
vim.keymap.set('n', '<leader>gc', '<cmd>Telescope git_commits<CR>') -- list all commits (use <CR> to checkout)
vim.keymap.set('n', '<leader>gfc', '<cmd>Telescope git_bcommits<CR>') -- list file commits (use <CR> to checkout)
vim.keymap.set('n', '<leader>gs', '<cmd>Telescope git_status<CR>') -- list current changes per file with diff preview

-- h (no highlight)
vim.keymap.set('n', '<leader>h', ':nohl<CR>') -- no search highlights

-- l (lsp)
vim.keymap.set('n', '<leader>lr', ':LspRestart<CR>') -- restart lsp

-- s (split)
vim.keymap.set('n', '<leader>sv', '<C-w>v') -- split window vertically
vim.keymap.set('n', '<leader>sh', '<C-w>s') -- split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=') -- make splits equal width & height
vim.keymap.set('n', '<leader>sm', ':MaximizerToggle<CR>') -- maximize split / restore split layout with vim-maximizer
vim.keymap.set('n', '<leader>sx', ':close<CR>') -- close current split (or use ZZ/ZQ)

-- t (tab)
vim.keymap.set('n', '<leader>tn', ':tabn<CR>') -- go to next tab
vim.keymap.set('n', '<leader>to', ':tabnew<CR>') -- open new tab
vim.keymap.set('n', '<leader>tp', ':tabp<CR>') -- go to previous tab
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>') -- close current tab

-- w (save)
vim.keymap.set('n', '<leader>w', ':w<CR>') -- save current buffer

-- x (close)
vim.keymap.set('n', '<leader>x', ':bd<CR>') -- close

local setup, wk = pcall(require, 'which-key') -- import comment plugin safely
if not setup then
  return
end

-- See: https://github.com/folke/which-key.nvim#%EF%B8%8F-configuration
wk.setup()

wk.register({
  f = {
    name = 'find', -- optional group name
    f = { '<cmd>Telescope find_files<cr>', 'File' },
    g = { '<cmd>Telescope git_files<cr>', 'Git File' },
    r = { '<cmd>Telescope oldfiles<cr>', 'Recent File' }, -- additional options for creating the keymap
    ['1'] = 'which_key_ignore', -- special label to hide it in the popup
  },
}, { prefix = '<leader>' })
