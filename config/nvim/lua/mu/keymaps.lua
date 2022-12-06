--------------------
-- NON-LEADER KEY --
--------------------

-- swap : and ,
vim.keymap.set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
vim.keymap.set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- tab through buffers
vim.keymap.set('n', '<tab>', '<cmd>bnext<cr>') -- go to next buffer
vim.keymap.set('n', '<s-tab>', '<cmd>bprev<cr>') -- go to previous buffer

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

wk.register({
  -- ['1'] = 'which_key_ignore', -- special label to hide it in the popup

  ['\\'] = { '<C-w>v', 'vertical split' },
  ['-'] = { '<C-w>s', 'horizontal split' },

  e = { '<cmd>NvimTreeToggle<cr>', 'explore' },

  h = { '<cmd>nohl<cr>', 'highlights off' },

  f = {
    name = 'find', -- optional group name
    b = { '<cmd>Telescope buffers<cr>', 'buffer' },
    c = { '<cmd>Telescope grep_string<cr>', 'cursor word' }, -- find string under cursor in cwd
    f = { '<cmd>Telescope find_files<cr>', 'file' }, -- fuzzy-find files in cwd (respects .gitignore)
    g = { '<cmd>Telescope git_files<cr>', 'git file' }, -- fuzzy-find git files in cwd
    h = { '<cmd>Telescope help_tags<cr>', 'help tag' }, -- fuzzy-find available help tags
    r = { '<cmd>Telescope oldfiles<cr>', 'recent file' }, -- sort files by most recent first
    s = { '<cmd>Telescope live_grep<CR>', 'string' }, -- fuzzy-find string in cwd
  },

  g = {
    name = 'git',
    b = { '<cmd>Telescope git_branches<cr>', 'branches (<cr> to checkout)' },
    c = { '<cmd>Telescope git_commits<cr>', 'commits (<cr> to checkout)' },
    fc = { '<cmd>Telescope git_bcommits<cr>', 'file commits (<cr> to checkout)' },
    s = { '<cmd>Telescope git_status<cr>', 'status' },
  },

  l = {
    name = 'LSP',
    r = { '<cmd>LspRestart<cr>', 'restart' },
  },

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
