-- see: https://www.lazyvim.org/plugins/ui#lualinenvim

local Util = require('lazyvim.util')
local icons = require('lazyvim.config').icons

local function get_venv()
  return (vim.bo.filetype == 'python' and vim.env.VIRTUAL_ENV) and '(' .. vim.env.VIRTUAL_ENV .. ')' or ''
end

local options = {
  component_separators = '',
  disabled_filetypes = { tabline = { 'alpha', 'dashboard', 'starter' } },
  globalstatus = true,
  section_separators = '',
  theme = 'auto',
}

local sections = {
  lualine_a = { 'mode' },
  lualine_b = {
    {
      'diagnostics',
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
    -- the larger the shorting_target number, the sooner the file path abbreviates
    -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
    -- { 'filename', path = 1, shorting_target = 60, symbols = { modified = '', readonly = '', unnamed = '' } },
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
    'filetype',
    get_venv,
  },
  lualine_y = {
    'diff',
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
  lualine_z = { 'branch' },
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
