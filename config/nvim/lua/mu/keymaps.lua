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

-- Easily exit help windows with Esc or q
vim.cmd([[
  autocmd Filetype help nmap <buffer> <Esc> :q<CR>
  autocmd Filetype help nmap <buffer> q :q<CR>
]])

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
  ['-'] = { '<c-w>s', 'horizontal split' },
  ['\\'] = { '<c-w>v', 'vertical split' },
  ['='] = { '<c-w>=', 'equal width splits' },
  ['['] = { '<cmd>vertical resize -3<cr>', 'reduce split size' },
  [']'] = { '<cmd>vertical resize +3<cr>', 'increase split size' },

  -- FIXME: get this to work? (see: https://vi.stackexchange.com/questions/21894/how-to-insert-a-console-log-for-word-under-cursor-in-new-line)
  -- c = { "<cmd> normal \"ayiwOconsole.log('<C-R>a:', <C-R>a);<Esc>", 'console.log word' },

  e = { '<cmd>NvimTreeToggle<cr>', 'explore' },

  f = {
    name = 'find', -- optional group name
    [','] = { '<cmd>Telescope command_history<cr>', 'recent command' },
    a = { '<cmd>Telescope find_files<cr>', 'any file' }, -- fuzzy-find files in cwd (respects .gitignore)
    b = { '<cmd>Telescope buffers<cr>', 'buffer' },
    -- reserve d/D for LSP (find document/project diagnostics)
    f = { '<cmd>Telescope git_files<cr>', 'git file' }, -- fuzzy-find git files in cwd
    h = { '<cmd>Telescope help_tags<cr>', 'help tag' }, -- fuzzy-find available help tags
    k = { '<cmd>Telescope keymaps<cr>', 'keymaps' }, -- fuzzy-find available keymaps
    m = { '<cmd>Telescope marks<cr>', 'marks' }, -- fuzzy-find bookmarks
    r = { '<cmd>Telescope oldfiles<cr>', 'recent file' }, -- sort files by most recent first
    R = { '<cmd>Telescope registers<cr>', 'registers' }, -- fuzzy-find register content
    s = { '<cmd>Telescope live_grep<CR>', 'string' }, -- fuzzy-find string in cwd
    w = { '<cmd>Telescope grep_string<cr>', 'word under cursor' }, -- find string under cursor in cwd
    z = { '<cmd>Telescope resume<cr>', 'resume' }, -- resume previous search
  },

  g = {
    name = 'git',
    b = { '<cmd>Telescope git_branches<cr>', 'branches' },
    B = { '<cmd>Git blame<cr>', 'blame' },
    c = { '<cmd>Telescope git_bcommits<cr>', 'commits (buffer)' },
    C = { '<cmd>Telescope git_commits<cr>', 'commits (project)' },
    d = { '<cmd>vert Gdiff<cr>', 'diff' },
    g = { '<cmd>Ggrep<cr>', 'grep' },
    m = { '<cmd>Git move<cr>', 'move' },
    p = { '<cmd>Git pull<cr>', 'pull' },
    P = { '<cmd>Git push<cr>', 'push' },
    s = { '<cmd>vert Git<cr>', 'status (in split)' },
    S = { '<cmd>tab Git<cr>', 'status (in tab)' },
  },

  h = { '<cmd>nohl<cr>', 'highlights off' },

  -- reserve l for LSP

  -- n = {
  --   name = 'session',
  --   d = { '<cmd>SDelete<cr>', 'delete' },
  --   l = { '<cmd>SLoad<cr>', 'load' },
  --   s = { '<cmd>SSave<cr>', 'save' },
  --   x = { '<cmd>SClose<cr>', 'close' },
  -- },
  --
  q = { '<cmd>q<cr>', 'quit window' },
  Q = { '<cmd>confirm qa<cr>', 'quit vim' },

  -- FIXME: can this work?
  -- R = { '<cmd>source $MYVIMRC<cr>', 'reload vim' },

  s = {
    name = 'split',
    ['\\'] = { '<C-w>v', 'vertically' },
    ['-'] = { '<C-w>s', 'horizontally' },
    ['='] = { '<C-w>=', 'equally' },
    h = { '<C-w>s', 'horizontally' },
    m = { '<cmd>MaximizerToggle<cr>', 'maximize / unmaximize' }, -- maximize split OR restore previous split layout (with vim-maximizer}
    o = { '<C-w>o', 'only keep this one' },
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

  x = { '<cmd>confirm Bdelete<cr>', 'close' }, -- close buffer but not split (with vim-bbye)
}, { prefix = '<leader>' })
