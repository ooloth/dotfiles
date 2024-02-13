-- see: https://www.lazyvim.org/plugins/ui#lualinenvim

local Util = require('lazyvim.util')
local icons = require('lazyvim.config').icons

local function get_venv()
  if vim.bo.filetype ~= 'python' then
    return ''
  end

  return '(' .. vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV or '  No venv activated' .. ')'
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

local sections = {
  lualine_a = { { 'mode', padding = 0, separator = { left = '', right = '' } } },
  lualine_b = {
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
    { Util.lualine.pretty_path() },
  },
  lualine_x = {
    {
      function()
        return '  ' .. require('dap').status()
      end,
      cond = function()
        return package.loaded['dap'] and require('dap').status() ~= ''
      end,
      color = Util.ui.fg('Debug'),
    },
    -- {
    --   require('lazy.status').updates,
    --   cond = require('lazy.status').has_updates,
    --   color = { fg = catppuccin['mauve'] },
    -- },
    'filetype',
    get_venv,
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
    event = 'VeryLazy',
    opts = function()
      return {
        extensions = { 'neo-tree', 'nvim-dap-ui', 'quickfix', 'toggleterm' },
        inactive_sections = {},
        options = options,
        sections = {},
        tabline = sections,
        theme = 'catppuccin',
      }
    end,
  },
}
