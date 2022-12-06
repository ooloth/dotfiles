---------------
-- BEHAVIOUR --
---------------

-- editing
vim.opt.backspace = 'indent,eol,start'
vim.opt.clipboard:append('unnamedplus') -- use the macos system clipboard when yanking, cutting or deleting
vim.opt.iskeyword:append('-') -- treat hyphens as part of a single word

-- searching
vim.opt.ignorecase = true -- assume I want a case-insensitive search if my search only includes lowercase characters
vim.opt.smartcase = true -- assume I want a case-sensitive search if my search includes uppercase characters

-- quitting
vim.opt.confirm = true -- offer to save changes to open files before :q

----------------
-- APPEARANCE --
----------------

-- colors
vim.opt.background = 'dark' -- default light/dark colorschemes to dark
vim.opt.termguicolors = true

-- cursor
vim.opt.cursorline = true

-- lines
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false

-- spacing
vim.opt.cmdheight = 0
vim.opt.signcolumn = 'yes'

-- split windows
vim.opt.splitbelow = true
vim.opt.splitright = true

-- tabs & indentation
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
