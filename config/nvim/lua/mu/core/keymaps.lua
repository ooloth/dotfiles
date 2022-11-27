vim.g.mapleader = ' '

-------------
-- GENERAL --
-------------

vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set('n', 'x', '"_x"') -- delete single character without copying into register 

-------------
-- PLUGINS --
-------------

-- vim-maximizer
vim.keymap.set('n', '<leader>sm', ':MaximizerToggle<CR>')

-- nvim-tree
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')

-- telescope
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>') -- find files within current working directory, respects .gitignore
vim.keymap.set('n', '<leader>fs', '<cmd>Telescope live_grep<CR>') -- find string in current working directory as you type
vim.keymap.set('n', '<leader>fc', '<cmd>Telescope grep_string<CR>') -- find string under cursor in current working directory
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>') -- list open buffers in current neovim instance
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>') -- list available help tags

-- telescope git commands (not on youtube nvim video)
vim.keymap.set('n', '<leader>gc', '<cmd>Telescope git_commits<CR>') -- list all git commits (use <CR> to checkout) ['gc' for git commits]
vim.keymap.set('n', '<leader>gfc', '<cmd>Telescope git_bcommits<CR>') -- list git commits for current file/buffer (use <CR> to checkout) ['gfc' for git file commits]
vim.keymap.set('n', '<leader>gb', '<cmd>Telescope git_branches<CR>') -- list git branches (use <CR> to checkout) ['gb' for git branch]
vim.keymap.set('n', '<leader>gs', '<cmd>Telescope git_status<CR>') -- list current changes per file with diff preview ['gs' for git status]

-- restart lsp server (not on youtube nvim video)
vim.keymap.set('n', '<leader>rs', ':LspRestart<CR>') -- mapping to restart lsp if necessary

-- lazygit
vim.keymap.set('n', '<leader>gg', 'lazygit')
----------------
-- LEADER KEY --
----------------

-- search
vim.keymap.set('n', '<leader>nh', ':nohl<CR>') -- clear search highlights

-- numbers
vim.keymap.set('n', '<leader>+', '<C-a>') -- increment number under cursor
vim.keymap.set('n', '<leader>-', '<C-x>') -- decrement number under cursor

-- windows 
vim.keymap.set('n', '<leader>sv', '<C-w>v') -- split window vertically
vim.keymap.set('n', '<leader>sh', '<C-w>s') -- split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=') -- make split windows equal width & height
vim.keymap.set('n', '<leader>sx', ':close<CR>') -- close current split window

-- tabs
vim.keymap.set('n', '<leader>to', ':tabnew<CR>') -- open new tab
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>') -- close current tab
vim.keymap.set('n', '<leader>tn', ':tabn<CR>') --  go to next tab
vim.keymap.set('n', '<leader>tp', ':tabp<CR>') --  go to previous tab
