-- statusline
local modes = {
  ["n"] = "NORMAL",
  ["no"] = "NORMAL",
  ["nt"] = "NORMAL",
  ["v"] = "VISUAL",
  ["V"] = "VISUAL LINE",
  [""] = "VISUAL BLOCK",
  ["s"] = "SELECT",
  ["S"] = "SELECT LINE",
  [""] = "SELECT BLOCK",
  ["i"] = "INSERT",
  ["ic"] = "INSERT",
  ["R"] = "REPLACE",
  ["Rv"] = "VISUAL REPLACE",
  ["c"] = "COMMAND",
  ["cv"] = "VIM EX",
  ["ce"] = "EX",
  ["r"] = "PROMPT",
  ["rm"] = "MOAR",
  ["r?"] = "CONFIRM",
  ["!"] = "SHELL",
  ["t"] = "TERMINAL",
}

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  return string.format(" %s ", modes[current_mode]):upper()
end

-- TODO: set the highlight groups reference here elsewhere (for each theme)
local function update_mode_colors()
  local current_mode = vim.api.nvim_get_mode().mode
  local mode_color = "%#StatusLineAccent#"
  if modes[current_mode] == "NORMAL" then
    mode_color = "%#StatuslineAccent#"
  elseif modes[current_mode] == "INSERT" then
    mode_color = "%#StatuslineInsertAccent#"
  elseif modes[current_mode]:find('VISUAL') then
    mode_color = "%#StatuslineVisualAccent#"
  elseif modes[current_mode] == "REPLACE" then
    mode_color = "%#StatuslineReplaceAccent#"
  elseif modes[current_mode] == "COMMAND" then
    mode_color = "%#StatuslineCmdLineAccent#"
  elseif modes[current_mode] == "TERMINAL" then
    mode_color = "%#StatuslineTerminalAccent#"
  end
  return mode_color
end

-- see: https://github.com/nvim-lualine/lualine.nvim/blob/master/lua/lualine/components/searchcount.lua
local function searchcount()
  if vim.v.hlsearch == 0 then
    return ''
  end

  local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
  if not ok or next(result) == nil then
    return ''
  end

  local denominator = math.min(result.total, result.maxcount)
  return string.format('[%d/%d]', result.current, denominator)
end

local function lineinfo()
  return " %l/%L "
end

Statusline = {}

Statusline.update = function()
  return table.concat {
    "%#Statusline#",
    update_mode_colors(),
    mode(),
    "%#Normal# ",
    "%=%#Normal# ",
    searchcount(),
    "%=%#StatusLineExtra#",
    lineinfo(),
  }
end

local opt = vim.opt

opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.cmdheight = 0
opt.completeopt = "menu,menuone,noselect"
opt.cursorline = true                          -- Enable highlighting of the current line
opt.formatoptions = "jcroqlnt"                 -- tcqj
opt.ignorecase = true                          -- Ignore case
opt.laststatus = 3                             -- Always show one global statusline
opt.mouse = "a"                                -- Enable mouse mode
opt.number = false                             -- Print line number
opt.pumblend = 10                              -- Popup blend
opt.pumheight = 10                             -- Maximum number of entries in a popup
opt.relativenumber = false                     -- Relative line numbers
opt.scrolloff = 10                             -- Lines of context
opt.shortmess:append({ W = true, I = true, c = true })
opt.showmode = false                           -- Don't show mode since we have a statusline
opt.sidescrolloff = 8                          -- Columns of context
opt.signcolumn = "no"
opt.smartcase = true                           -- Don't ignore case with capitals
opt.statusline = '%!v:lua.Statusline.update()' -- see :help statusline, :help v:lua
opt.termguicolors = true                       -- True color support
opt.timeoutlen = 300
opt.wildmode = "longest:full,full"             -- Command-line completion mode
opt.winminwidth = 5                            -- Minimum window width
opt.wrap = false                               -- Disable line wrap

------------------
-- Autocommands --
------------------
-- see: https://neovim.io/doc/user/api.html#nvim_create_autocmd()

-- Allow deleting lines + start with cursor at the bottom
vim.api.nvim_create_autocmd('VimEnter', {
  command = [[
    setlocal modifiable
    normal G
  ]]
})

-- Nicer line highlighting while using Material Ocean theme in terminal
-- see: https://neovim.io/doc/user/syntax.html#highlight-groups
-- see: https://github.com/material-theme/vsc-material-theme/blob/main/scripts/generator/settings/specific/ocean.ts
vim.api.nvim_create_autocmd('ColorScheme', {
  command = [[
    highlight CursorLine guibg=#292D3E cterm=NONE
    highlight Visual guibg=#292D3E cterm=NONE
    highlight Search guibg=#FFFFFF guifg=#000000 cterm=NONE
    highlight IncSearch guibg=#000000 guifg=#FFFFFF cterm=NONE
    highlight CurSearch guibg=#FFCB6B guifg=#000000 cterm=NONE
    highlight StatuslineAccent guibg=#82AAFF guifg=#000000 cterm=NONE
    highlight StatuslineInsertAccent guibg=#C3E88D guifg=#000000 cterm=NONE
    highlight StatuslineVisualAccent guibg=#C792EA guifg=#000000 cterm=NONE
    highlight StatuslineReplaceAccent guibg=#916b53 guifg=#000000 cterm=NONE
    highlight StatuslineCmdLineAccent guibg=#FFCB6B guifg=#000000 cterm=NONE
    highlight StatuslineTerminalAccent guibg=#F78C6C guifg=#000000 cterm=NONE
  ]]
})

vim.cmd.colorscheme "default"

-------------
-- KEYMAPS --
-------------

local set = vim.keymap.set

vim.g.mapleader = " "

-- avoid entering terminal mode in a read only buffer
set('n', 'i', '<Esc>', { silent = true })
set('n', 'I', '<Esc>', { silent = true })
set('n', 'a', '<Esc>', { silent = true })
set('n', 'A', '<Esc>', { silent = true })
set('n', 'o', '<Esc>', { silent = true })
set('n', 'O', '<Esc>', { silent = true })
set('n', 'c', '<Esc>', { silent = true })
set('n', 's', '<Esc>', { silent = true })

-- swap : and ,
set({ 'n', 'v' }, ',', ':') -- enter command mode with , instead of :
set({ 'n', 'v' }, ':', ',') -- navigate f and t results using ;/: (like n/N for / results)

-- line beginning + end
set({ 'n', 'v' }, '<S-h>', '^', { silent = true })
set({ 'n', 'v' }, '<S-l>', '$', { silent = true })
set({ 'n', 'v' }, '$', '<Esc>', { silent = true }) -- practice using L instead

-- clear search highlights
set('n', '<esc>', '<cmd>nohlsearch<CR><Esc>', { silent = true })
