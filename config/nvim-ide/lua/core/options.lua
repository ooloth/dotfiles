-- TODO: move filetype associations to treesitter settings?
-- https://neovim.io/doc/user/treesitter.html

-- see: https://www.lazyvim.org/configuration/general#options

local opt = vim.opt

opt.autoindent = true -- copy indent from current line when starting new one
opt.autowrite = true -- Enable auto write
opt.background = 'dark' -- colorschemes that can be light or dark will be made dark
-- opt.backspace = 'indent,eol,start' -- allow backspace on indent, end of line or insert mode start position
opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus' -- Sync with system clipboard if not in SSH
opt.cmdheight = 0
opt.completeopt = 'menu,menuone,noselect'
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ', -- hide ~ at end of buffer
}
-- opt.foldexpr = "v:lua.require'lazyvim.util'.ui.foldexpr()"
opt.foldlevel = 99
opt.foldmethod = 'expr'
opt.foldtext = ''
-- opt.formatexpr = "v:lua.require'lazyvim.util'.format.formatexpr()"
opt.formatoptions = 'jcroqlnt' -- tcqj
opt.grepformat = '%f:%l:%c:%m'
opt.grepprg = 'rg --vimgrep'
opt.ignorecase = true -- Ignore case
opt.inccommand = 'nosplit' -- preview incremental substitute
opt.laststatus = 3 -- global statusline
-- opt.laststatus = 0 -- disable statusline since showing in tabline (via lualine)
opt.linebreak = true -- Wrap lines at convenient points
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = '' -- disable mouse mode (use 'a' to enable)
opt.number = false -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = false -- Relative line numbers
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
-- opt.signcolumn = 'no'
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.smoothscroll = true
-- opt.spell = false
opt.spelllang = { 'en' }
opt.spelloptions:append('noplainbuffer')
opt.splitbelow = true -- Put new windows below current
opt.splitkeep = 'screen'
opt.splitright = true -- Put new windows right of current
-- opt.statuscolumn = [[%!v:lua.require'lazyvim.util'.ui.statuscolumn()]]
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = 'longest:full,full' -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- checkhealth
vim.cmd([[
  let g:loaded_perl_provider = 0
  let g:loaded_ruby_provider = 0
]])

-- custom filename -> filetype associations
vim.filetype.add({
  extension = {
    -- see: https://sbulav.github.io/vim/neovim-improving-work-with-terraform/#correctly-detecting-tf-filetype
    tf = 'terraform',
    tfvars = 'terraform',
    tfstate = 'json',
  },
  filename = {
    ['tsconfig.json'] = 'jsonc',
    -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#docker_compose_language_service
    ['docker-compose.yaml'] = 'yaml.docker-compose',
  },
  pattern = {
    ['docker-compose.*%.yaml'] = 'yaml.docker-compose',
    ['.*/kitty/.*%.conf'] = 'bash',
    ['.*/kitty/.*/.*%.conf'] = 'bash',
    ['.*/.vscode/.*%.json'] = 'jsonc',
    ['.*/vscode/.*%.json'] = 'jsonc',
  },
})
