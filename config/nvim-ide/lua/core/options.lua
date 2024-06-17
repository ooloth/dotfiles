local opt = vim.opt

opt.clipboard = 'unnamedplus' -- Sync with system clipboard
opt.cmdheight = 0
opt.completeopt = 'menu,menuone,noselect'
opt.cursorline = true -- Enable highlighting of the current line
opt.formatoptions = 'jcroqlnt' -- tcqj
opt.ignorecase = true -- Ignore case
opt.laststatus = 3 -- Always show one global statusline
opt.mouse = 'a' -- Enable mouse mode
opt.number = false -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = false -- Relative line numbers
opt.scrolloff = 10 -- Lines of context
opt.shortmess:append({ W = true, I = true, c = true })
opt.showmode = false -- Don't show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = 'no'
opt.smartcase = true -- Don't ignore case with capitals
-- opt.statusline = '%!v:lua.Statusline.update()' -- see :help statusline, :help v:lua
opt.termguicolors = true -- True color support
opt.timeoutlen = 300
opt.wildmode = 'longest:full,full' -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap