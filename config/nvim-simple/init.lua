local opt = vim.opt

opt.autowrite = true          -- Enable auto write
opt.clipboard = "unnamedplus" -- Sync with system clipboard
-- opt.cmdheight = 0
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 3           -- Hide * markup for bold and italic
opt.confirm = true             -- Confirm to save changes before exiting modified buffer
opt.cursorline = true          -- Enable highlighting of the current line
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true      -- Ignore case
opt.inccommand = "nosplit" -- preview incremental substitute
opt.laststatus = 0
opt.list = true            -- Show some invisible characters (tabs...
opt.mouse = "a"            -- Enable mouse mode
opt.number = false         -- Print line number
opt.pumblend = 10          -- Popup blend
opt.pumheight = 10         -- Maximum number of entries in a popup
opt.relativenumber = false -- Relative line numbers
opt.scrolloff = 10         -- Lines of context
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opt.shiftround = true      -- Round indent
opt.shiftwidth = 2         -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true })
-- opt.showmode = false       -- Dont show mode since we have a statusline
opt.sidescrolloff = 8    -- Columns of context
opt.signcolumn = "no"
opt.smartcase = true     -- Don't ignore case with capitals
opt.smartindent = true   -- Insert indents automatically
opt.spelllang = { "en" }
opt.splitbelow = true    -- Put new windows below current
opt.splitright = true    -- Put new windows right of current
opt.tabstop = 2          -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.timeoutlen = 300
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200               -- Save swap file and trigger CursorHold
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5                -- Minimum window width
opt.wrap = false                   -- Disable line wrap

-- Nicer line highlighting while using Material Ocean theme in terminal
vim.api.nvim_create_autocmd('ColorScheme', {
  command = [[
    highlight CursorLine guibg=#292D3E cterm=NONE
    highlight Visual guibg=#292D3E cterm=NONE
    highlight Search guibg=#FFCB6B cterm=NONE
  ]]
})

vim.cmd.colorscheme "default"

local set = vim.keymap.set

vim.g.mapleader = " "

-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- line beginning + end
set({ 'n', 'v' }, '<S-h>', '^', { desc = 'Go to start of line', silent = true })
set({ 'n', 'v' }, '<S-l>', '$', { desc = 'Go to end of line', silent = true })
-- set({ 'n', 'v' }, '^', '<noop>', { silent = true }) -- practice using H instead
set({ 'n', 'v' }, '$', '<noop>', { silent = true }) -- practice using L instead

-- "changes"
set('n', ']c', 'g,', { desc = 'Next change' })     -- go to next change with g;
set('n', '[c', 'g;', { desc = 'Previous change' }) -- go to next change with g;
set('n', 'g;', 'g,', { desc = 'Next change' })     -- go to next change with g;
set('n', 'g:', 'g;', { desc = 'Previous change' }) -- go to previous change with g;

set('n', '<leader><space>', '<cmd>w<cr>', { desc = 'Save' })
set('n', '<leader>s', '<cmd>w<cr>', { desc = 'Save' })

-- "tab"
set('n', '<leader>tt', '<cmd>tabnew<cr>', { desc = 'New tab' })
set('n', '<leader>tf', '<cmd>tabfirst<cr>', { desc = 'First tab' })
set('n', '<leader>tl', '<cmd>tablast<cr>', { desc = 'Last tab' })
set('n', '<leader>t]', '<cmd>tabnext<cr>', { desc = 'Next tab' })
set('n', '<leader>tn', '<cmd>tabnext<cr>', { desc = 'Next tab' })
set('n', '<leader>t[', '<cmd>tabprevious<cr>', { desc = 'Previous tab' })
set('n', '<leader>tp', '<cmd>tabprevious<cr>', { desc = 'Previous tab' })
set('n', '<leader>tc', '<cmd>tabclose<cr>', { desc = 'Close tab' })
set('n', ']t', '<cmd>tabnext<cr>', { desc = 'Next tab' })
set('n', '[t', '<cmd>tabprevious<cr>', { desc = 'Next tab' })

-- "window"
set('n', '<leader>\\', '<c-w>v', { desc = 'Split right' })
set('n', '<leader>w\\', '<c-w>v', { desc = 'Split right' })
set('n', '<leader>-', '<c-w>v', { desc = 'Split below' })
set('n', '<leader>w-', '<c-w>v', { desc = 'Split below' })
set('n', '<leader>=', '<c-w>=', { desc = 'Resize equally' })
set('n', '<leader>w=', '<c-w>=', { desc = 'Resize equally' })
set('n', '<leader>[', '<cmd>vertical resize -3<cr>', { desc = 'Reduce size' })
set('n', '<leader>w[', '<cmd>vertical resize -3<cr>', { desc = 'Reduce size' })
set('n', '<leader>]', '<cmd>vertical resize +3<cr>', { desc = 'Increase size' })
set('n', '<leader>w]', '<cmd>vertical resize +3<cr>', { desc = 'Increase size' })
set('n', '<leader>wc', '<c-w>c', { desc = 'Close' })
-- "leader-wm" = toggle maximize window (see vim-maximizer.lua}
set('n', '<leader>wo', '<c-w>o', { desc = 'Only keep this one' })
set('n', '<leader>wt', '<cmd>tab split<cr>', { desc = 'Open in new tab' })
set('n', '<leader>ww', '<cmd>w<cr>', { desc = 'Write' })

-- clear search highlights
set('n', '<esc>', '<cmd>nohl<CR>', { silent = true })

-- see: https://github.com/christoomey/vim-tmux-navigator/blob/master/plugin/tmux_navigator.vim
vim.cmd([[
  noremap <silent> <c-h> :<C-U>TmuxNavigateLeft<cr>
  noremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
  noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
  noremap <silent> <c-l> :<C-U>TmuxNavigateRight<cr>
  noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>
]])
