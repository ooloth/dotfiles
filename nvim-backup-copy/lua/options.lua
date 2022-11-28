local cmd = vim.cmd
local opt = vim.opt

-- buffers
opt.hidden = true -- persist buffers in the background
opt.splitright = true
opt.splitbelow = true

-- write buffer after leaving insert mode or changing text in normal mode
-- FIXME: do in buffer, but not in Telescope search field
-- cmd([[
--   autocmd InsertLeave,TextChanged * update
-- ]])

-- clipboard
opt.clipboard:append('unnamedplus') -- use the system clipboard for everything

-- completion
opt.completeopt = { 'menuone', 'noselect'}
opt.shortmess:append('c') -- don't pass messages to |ins-completion-menu|

-- cursor
opt.scrolloff = 22 -- keep cursor this many lines away from top/bottom

-- cursor line
opt.cursorline = true

cmd([[
  autocmd InsertEnter * set nocursorline
  autocmd InsertLeave * set cursorline
]])

-- formatting
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'
opt.fileencodings = { 'utf-8' }

-- indenting
opt.autoindent = true -- always set autoindenting on
opt.copyindent = true -- copy the previous indentation on autoindenting
opt.expandtab = true -- convert tabs to spaces
opt.shiftround = true -- use multiple of shiftwidth when indenting with '<' and '>'
opt.shiftwidth = 2
opt.showmatch = true -- show matching parenthesis
opt.smartindent = true
opt.softtabstop = 2
opt.tabstop = 2

-- line wrapping
opt.wrap = true
opt.linebreak = true -- keep words intact when wrapping
opt.breakindent = true -- wrap with same indentation

-- remove trailing whitespace on save
cmd([[autocmd BufWritePre * :%s/\s\+$//e]])

-- history
opt.history = 1000 -- remember more commands and search history
opt.backup = false -- no .bak (rely on git for version control)
opt.swapfile = false -- no .swap
opt.writebackup = false -- some servers have issues with backup files
opt.undofile = true -- use a separate undo file
opt.undolevels = 200 -- make more changes undoable
opt.updatetime = 300 -- time (in ms) to write to swap file

-- search (current buffer)
opt.hlsearch = true
opt.incsearch = true -- show search matches while typing
opt.ignorecase = true -- ignore case when searching...
opt.smartcase = true -- ...unless search includes uppercase letters


-- UX
opt.cmdheight = 2
opt.confirm = true -- instead of failing, ask me what to do
opt.errorbells = false -- shhhhh
opt.lazyredraw = true -- wait to redraw screen until macro is complete
opt.inccommand = 'nosplit' -- live text substitution preview
opt.number = true -- show line numbers
opt.relativenumber = true -- show relative line numbers
opt.signcolumn = 'yes'
opt.timeoutlen = 500 -- respond faster to keypresses (default is 1000)
opt.ttimeoutlen = 1
opt.updatetime = 50 -- reduce lag (default is 4000)
