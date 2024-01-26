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
  lualine_x = { 'filetype', get_venv },
  lualine_y = { 'diff' },
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
