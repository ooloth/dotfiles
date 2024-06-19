-- TODO: -- TODO: https://www.lazyvim.org/plugins/ui#lualinenvim
-- TODO: https://www.lazyvim.org/plugins/ui#lualinenvim
-- TODO: show @recording messages in statusline instead of notify pop-ups? https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#show-recording-messages

local Util = require('lazyvim.util')
local icons = require('lazyvim.config').icons

local function get_venv()
  if vim.bo.filetype ~= 'python' then
    return ''
  end

  if not vim.env.VIRTUAL_ENV then
    return '(  No venv activated)'
  end

  -- example path = '/Users/michael/.pyenv/versions/3.12.1/envs/scraper'
  local function get_version_and_venv(path_to_pyenv_venv)
    local parts = {}
    for part in string.gmatch(path_to_pyenv_venv, '([^/]+)') do
      table.insert(parts, part)
    end
    local version = parts[#parts - 2]
    local venv = parts[#parts]
    return version .. ' (' .. venv .. ')'
  end

  return get_version_and_venv(vim.env.VIRTUAL_ENV)
end

-- see: https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/palettes/mocha.lua
local catppuccin = {
  rosewater = '#f5e0dc',
  flamingo = '#f2cdcd',
  pink = '#f5c2e7',
  mauve = '#cba6f7',
  red = '#f38ba8',
  maroon = '#eba0ac',
  peach = '#fab387',
  yellow = '#f9e2af',
  green = '#a6e3a1',
  teal = '#94e2d5',
  sky = '#89dceb',
  sapphire = '#74c7ec',
  blue = '#89b4fa',
  lavender = '#b4befe',
  text = '#cdd6f4',
  subtext1 = '#bac2de',
  subtext0 = '#a6adc8',
  overlay2 = '#9399b2',
  overlay1 = '#7f849c',
  overlay0 = '#6c7086',
  surface2 = '#585b70',
  surface1 = '#45475a',
  surface0 = '#313244',
  base = '#1e1e2e',
  mantle = '#181825',
  crust = '#11111b',
}

-- set transparent background:
-- see: https://www.reddit.com/r/neovim/comments/zh4kc8/comment/j0qtbb4/?utm_source=share&utm_medium=web2x&context=3
local custom_catppuccin = require('lualine.themes.catppuccin')
custom_catppuccin.normal.c.bg = nil

local options = {
  component_separators = '',
  -- disabled_filetypes = { 'dashboard', tabline = { 'alpha', 'dashboard', 'starter' } },
  globalstatus = true,
  section_separators = '',
  theme = custom_catppuccin,
}

local empty = {
  -- TODO: return '' if no diagnostics?
  function()
    return '█'
  end,
  padding = 0,
  color = { fg = catppuccin['base'], bg = catppuccin['base'] },
}

-- see: https://github.com/nvim-lualine/lualine.nvim?tab=readme-ov-file#general-component-options
local sections = {
  lualine_a = { { 'mode', padding = 0, separator = { left = '', right = '' } } },
  lualine_b = {
    empty,
    { 'location', padding = 0, separator = { left = '', right = '' } },
    empty,
    {
      'diagnostics',
      padding = 0,
      separator = { left = '', right = '' },
      symbols = {
        error = icons.diagnostics.Error,
        warn = icons.diagnostics.Warn,
        info = icons.diagnostics.Info,
        hint = icons.diagnostics.Hint,
      },
    },
  },
  lualine_c = {
    empty,
    -- see: https://github.com/nvim-lualine/lualine.nvim?tab=readme-ov-file#filename-component-options
    { 'filename', padding = 0, path = 1 },
    -- see: https://github.com/nvim-lualine/lualine.nvim?tab=readme-ov-file#windows-component-options
    -- { 'windows', show_filename_only = false },
    -- { Util.lualine.pretty_path() },
  },
  lualine_x = {
    {
      -- See when I'm recording a macro:
      -- https://github.com/folke/noice.nvim?tab=readme-ov-file#-statusline-components
      require('noice').api.status.mode.get,
      cond = require('noice').api.status.mode.has,
      color = { fg = catppuccin['yellow'] },
    },
    'searchcount',
    {
      function()
        return '  ' .. require('dap').status()
      end,
      cond = function()
        return package.loaded['dap'] and require('dap').status() ~= ''
      end,
      color = Util.ui.fg('Debug'),
    },
    {
      'filetype',
      cond = function()
        local ignored_filetypes = { 'alpha', 'dashboard', 'neo-tree', 'floaterm' }
        return not vim.tbl_contains(ignored_filetypes, vim.bo.filetype)
      end,
    },
    { get_venv, padding = { left = 0, right = 1 } },
  },
  lualine_y = {
    { 'diff', padding = 0, separator = { left = '', right = '' } },
    empty,
  },
  lualine_z = { { 'branch', padding = 0, separator = { left = '', right = '' } } },
}

return {
  {
    'nvim-lualine/lualine.nvim',
    lazy = false,
    opts = function()
      return {
        extensions = { 'neo-tree', 'nvim-dap-ui', 'quickfix', 'toggleterm' }, -- TODO: floaterm? others?
        inactive_sections = {},
        options = options,
        sections = sections,
        theme = 'catppuccin',
      }
    end,
  },
}
