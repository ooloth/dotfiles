vim.g.mapleader = ' '

-------------
-- GENERAL --
-------------

vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set('n', 'x', '"_x"') -- delete single character without copying into register 

-------------
-- PLUGINS --
-------------

vim.keymap.set('n', '<leader>sm', ':MaximizerToggle<CR>')
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')

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
