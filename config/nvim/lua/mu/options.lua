-- line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- tabs & indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- line wrapping
vim.opt.wrap = false

-- search
vim.opt.ignorecase = true -- assume I want a case-insensitive search if my search only includes lowercase characters
vim.opt.smartcase = true -- assume I want a case-sensitive search if my search includes uppercase characters

-- cursor line
vim.opt.cursorline = true

-- appearance
vim.opt.termguicolors = true
vim.opt.background = 'dark' -- default light/dark colorschemes to dark
vim.opt.signcolumn = 'yes'
vim.opt.cmdheight = 0

-- backspace
vim.opt.backspace = 'indent,eol,start'

-- clipboard
vim.opt.clipboard:append('unnamedplus') -- use the macos system clipboard when yanking, cutting or deleting

-- split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

-- editing
vim.opt.iskeyword:append('-') -- treat hyphens as part of a single word
