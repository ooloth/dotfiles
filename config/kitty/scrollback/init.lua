local opt = vim.opt

opt.clipboard = "unnamedplus" -- Sync with system clipboard
-- opt.cmdheight = 0
opt.completeopt = "menu,menuone,noselect"
opt.cursorline = true          -- Enable highlighting of the current line
opt.formatoptions = "jcroqlnt" -- tcqj
opt.ignorecase = true          -- Ignore case
opt.laststatus = 0
opt.mouse = "a"                -- Enable mouse mode
opt.number = false             -- Print line number
opt.pumblend = 10              -- Popup blend
opt.pumheight = 10             -- Maximum number of entries in a popup
opt.relativenumber = false     -- Relative line numbers
opt.scrolloff = 10             -- Lines of context
opt.shortmess:append({ W = true, I = true, c = true })
-- opt.showmode = false       -- Dont show mode since we have a statusline
opt.sidescrolloff = 8              -- Columns of context
opt.signcolumn = "no"
opt.smartcase = true               -- Don't ignore case with capitals
opt.termguicolors = true           -- True color support
opt.timeoutlen = 300
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5                -- Minimum window width
opt.wrap = false                   -- Disable line wrap

-- Nicer line highlighting while using Material Ocean theme in terminal
vim.api.nvim_create_autocmd('ColorScheme', {
  command = [[
    highlight CursorLine guibg=#292D3E cterm=NONE
    highlight Visual guibg=#292D3E cterm=NONE
    highlight Search guibg=#FFCB6B cterm=NONE
    highlight IncSearch guibg=#FFCB6B cterm=NONE
    highlight CurSearch guibg=#ff9cac cterm=NONE
  ]]
})

vim.cmd.colorscheme "default"

-- Allow deleting lines and start at the bottom
vim.api.nvim_create_autocmd('VimEnter', {
  command = [[
    setlocal modifiable
    normal G
  ]]
})

local set = vim.keymap.set

vim.g.mapleader = " "

-- avoid terminal mode in read only buffers
set('n', 'i', '<Esc>', { silent = true })
set('n', 'I', '<Esc>', { silent = true })
set('n', 'a', '<Esc>', { silent = true })
set('n', 'A', '<Esc>', { silent = true })
set('n', 'o', '<Esc>', { silent = true })
set('n', 'O', '<Esc>', { silent = true })
set('n', 'c', '<Esc>', { silent = true })
set('n', 's', '<Esc>', { silent = true })

set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- line beginning + end
set({ 'n', 'v' }, '<S-h>', '^', { silent = true })
set({ 'n', 'v' }, '<S-l>', '$', { silent = true })

-- clear search highlights
set('n', '<esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })
