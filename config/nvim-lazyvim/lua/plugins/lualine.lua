-- see: https://www.lazyvim.org/plugins/ui#lualinenvim

local Util = require('lazyvim.util')
local icons = require('lazyvim.config').icons

local function get_venv()
  if vim.bo.filetype ~= 'python' then
    return ''
  end

  return '(' .. vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV or '  No venv activated' .. ')'
end

local options = {
  component_separators = '',
  disabled_filetypes = { tabline = { 'alpha', 'dashboard', 'starter' } },
  globalstatus = true,
  section_separators = '',
  theme = 'auto',
}

local empty = {
  function()
    return '█'
  end,
  padding = 0,
  color = { fg = '#1e1e2e', bg = '#1e1e2e' },
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
    {
      require('lazy.status').updates,
      cond = require('lazy.status').has_updates,
      color = Util.ui.fg('Special'),
    },
    { 'filetype' },
    { get_venv },
  },
  lualine_y = {
    { 'diff', padding = 0, separator = { left = '', right = '' } },
    empty,
    -- 'diff',
    -- {
    --   'diff',
    --   symbols = {
    --     added = icons.git.added,
    --     modified = icons.git.modified,
    --     removed = icons.git.removed,
    --   },
    --   source = function()
    --     local gitsigns = vim.b.gitsigns_status_dict
    --     if gitsigns then
    --       return {
    --         added = gitsigns.added,
    --         modified = gitsigns.changed,
    --         removed = gitsigns.removed,
    --       }
    --     end
    --   end,
    -- },
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
      }
    end,
  },
}
