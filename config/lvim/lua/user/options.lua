-- buffers
vim.opt.hidden = true -- persist buffers in the background
vim.opt.splitright = true
vim.opt.splitbelow = true

-- clipboard
-- vim.opt.clipboard:append("unnamedplus") -- use the system clipboard for everything

-- completion
-- vim.opt.completeopt = { "menuone", "noselect" }
-- vim.opt.shortmess:append("c") -- don't pass messages to |ins-completion-menu|

-- cursor
-- vim.opt.scrolloff = 22 -- keep cursor this many lines away from top/bottom
-- vim.opt.cursorline = true

-- vim.cmd([[
--   autocmd InsertEnter * set nocursorline
--   autocmd InsertLeave * set cursorline
-- ]])

-- -- formatting
-- vim.opt.encoding = "utf-8"
-- vim.opt.fileencoding = "utf-8"
-- vim.opt.fileencodings = { "utf-8" }

-- -- indenting
-- vim.opt.autoindent = true -- always set autoindenting on
-- vim.opt.copyindent = true -- copy the previous indentation on autoindenting
-- vim.opt.expandtab = true -- convert tabs to spaces
-- vim.opt.shiftround = true -- use multiple of shiftwidth when indenting with '<' and '>'
-- vim.opt.shiftwidth = 2
-- vim.opt.showmatch = true -- show matching parenthesis
-- vim.opt.smartindent = true
-- vim.opt.softtabstop = 2
-- vim.opt.tabstop = 2

-- -- line wrapping
-- vim.opt.wrap = true
-- vim.opt.linebreak = true -- keep words intact when wrapping
-- vim.opt.breakindent = true -- wrap with same indentation

-- -- remove trailing whitespace on save
-- vim.cmd([[autocmd BufWritePre * :%s/\s\+$//e]])

-- -- history
-- vim.opt.history = 1000 -- remember more commands and search history
-- vim.opt.backup = false -- no .bak (rely on git for version control)
-- vim.opt.swapfile = false -- no .swap
-- vim.opt.writebackup = false -- some servers have issues with backup files
-- vim.opt.undofile = true -- use a separate undo file
-- vim.opt.undolevels = 200 -- make more changes undoable
-- vim.opt.updatetime = 300 -- time (in ms) to write to swap file

-- -- search (current buffer)
-- vim.opt.hlsearch = true
-- vim.opt.incsearch = true -- show search matches while typing
-- vim.opt.ignorecase = true -- ignore case when searching...
-- vim.opt.smartcase = true -- ...unless search includes uppercase letters

-- -- UX
-- vim.opt.cmdheight = 2
-- vim.opt.confirm = true -- instead of failing, ask me what to do
-- vim.opt.errorbells = false -- shhhhh
-- vim.opt.lazyredraw = true -- wait to redraw screen until macro is complete
-- vim.opt.inccommand = "nosplit" -- live text substitution preview
-- vim.opt.number = true -- show line numbers
-- vim.opt.relativenumber = true -- show relative line numbers
-- vim.opt.signcolumn = "yes"
-- vim.opt.timeoutlen = 500 -- respond faster to keypresses (default is 1000)
-- vim.opt.ttimeoutlen = 1
-- vim.opt.updatetime = 50 -- reduce lag (default is 4000)

-- -- syntax highlighting vim.opt.ons
-- vim.cmd("filetype plugin indent on")
-- vim.cmd("syntax enable")

-- if not vim.fn.has("gui_running") then
--   vim.opt.t_Co = 256
-- end

-- if vim.fn.has("termguicolors") then
--   vim.opt.termguicolors = true
--   vim.cmd([[
--       let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
--       let &t_8b = "\\<Esc>[48;2;%lu;%lu;%lum"
--     ]])
-- end

-- vim.opt.re = 0 -- https://github.com/HerringtonDarkholme/yats.vim#config

-- -- highlight MDX like MD
-- vim.cmd([[
--   autocmd BufNewFile,BufRead *.mdx set filetype=markdown.mdx
-- ]])
