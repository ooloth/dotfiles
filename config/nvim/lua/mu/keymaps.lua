--------------------
-- NON-LEADER KEY --
--------------------

-- swap : and ,
vim.keymap.set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
vim.keymap.set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- tab through buffers
vim.keymap.set('n', '<tab>', '<cmd>bnext<cr>') -- go to next buffer
vim.keymap.set('n', '<s-tab>', '<cmd>bprev<cr>') -- go to previous buffer

-- move lines with up/down arrows
vim.keymap.set('n', '<down>', ':m .+1<CR>==')
vim.keymap.set('n', '<up>', ':m .-2<CR>==')
vim.keymap.set('i', '<down>', '<Esc>:m .+1<CR>==gi')
vim.keymap.set('i', '<up>', '<Esc>:m .-2<CR>==gi')
vim.keymap.set('v', '<down>', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', '<up>', ":m '<-2<CR>gv=gv")

-- left/right through tabs
vim.keymap.set('n', '<right>', 'gt') -- go to next tab
vim.keymap.set('n', '<left>', 'gT') -- go to next tab

----------------
-- LEADER KEY --
----------------

vim.g.mapleader = ' '

local setup, wk = pcall(require, 'which-key') -- import comment plugin safely
if not setup then
  return
end

-- See: https://github.com/folke/which-key.nvim#%EF%B8%8F-configuration
wk.setup()

-- NOTE: attach LSP mappings in lsp-config.lua (instead of here)
wk.register({
  ['-'] = { '<C-w>s', 'horizontal split' },
  ['\\'] = { '<C-w>v', 'vertical split' },

  e = { '<cmd>NvimTreeToggle<cr>', 'explore' },

  f = {
    name = 'find', -- optional group name
    b = { '<cmd>Telescope buffers<cr>', 'buffer' },
    -- reserve fd/fD for LSP (find document/project diagnostics)
    f = { '<cmd>Telescope find_files<cr>', 'file' }, -- fuzzy-find files in cwd (respects .gitignore)
    g = { '<cmd>Telescope git_files<cr>', 'git file' }, -- fuzzy-find git files in cwd
    h = { '<cmd>Telescope help_tags<cr>', 'help tag' }, -- fuzzy-find available help tags
    r = { '<cmd>Telescope oldfiles<cr>', 'recent file' }, -- sort files by most recent first
    s = { '<cmd>Telescope live_grep<CR>', 'string' }, -- fuzzy-find string in cwd
    w = { '<cmd>Telescope grep_string<cr>', 'word under cursor' }, -- find string under cursor in cwd
  },

  g = {
    name = 'git',
    b = { '<cmd>Telescope git_branches<cr>', 'branches (<cr> to checkout)' },
    c = { '<cmd>Telescope git_commits<cr>', 'commits (<cr> to checkout)' },
    fc = { '<cmd>Telescope git_bcommits<cr>', 'file commits (<cr> to checkout)' },
    s = { '<cmd>Telescope git_status<cr>', 'status' },
  },

  h = { '<cmd>nohl<cr>', 'highlights off' },

  -- reserve l for LSP

  q = { '<cmd>q<cr>', 'quit' },
  Q = { '<cmd>qa<cr>', 'quit all' },

  s = {
    name = 'split',
    ['\\'] = { '<C-w>v', 'vertically' },
    ['-'] = { '<C-w>s', 'horizontally' },
    ['='] = { '<C-w>=', 'equally' },
    h = { '<C-w>s', 'horizontally' },
    m = { '<cmd>MaximizerToggle<cr>', 'maximize / unmaximize' }, -- maximize split OR restore previous split layout (with vim-maximizer}
    v = { '<C-w>v', 'vertically' },
    x = { '<cmd>close<cr>', 'close' }, -- close current split
  },

  t = {
    name = 'tab',
    n = { '<cmd>tabn<cr>', 'next' },
    o = { '<cmd>tabnew<cr>', 'open' },
    p = { '<cmd>tabp<cr>', 'previous' },
    x = { '<cmd>tabclose<cr>', 'close' },
  },

  w = { '<cmd>w<cr>', 'write' },

  x = { '<cmd>bd<cr>', 'close' },
}, { prefix = '<leader>' })
