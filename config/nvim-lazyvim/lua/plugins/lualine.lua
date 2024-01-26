local icons = require('lazyvim.config').icons

local function get_venv()
  return (vim.bo.filetype == 'python' and vim.env.VIRTUAL_ENV) and '(' .. vim.env.VIRTUAL_ENV .. ')' or ''
end

local options = {
  component_separators = '',
  -- disabled_filetypes = {},
  globalstatus = true,
  section_separators = '',
  theme = 'auto',
}

local sections = {
  lualine_a = { 'mode' },
  lualine_b = {
    {
      'diagnostics',
      padding = { left = 1, right = 0 },
      symbols = {
        error = icons.diagnostics.Error,
        warn = icons.diagnostics.Warn,
        info = icons.diagnostics.Info,
        hint = icons.diagnostics.Hint,
      },
    },
  },
  lualine_c = {
    -- the larger the shorting_target number, the sooner the file path abbreviates
    -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
    { 'filename', path = 1, shorting_target = 60, symbols = { modified = '', readonly = '', unnamed = '' } },
  },
  lualine_x = { 'filetype', get_venv },
  lualine_y = { 'progress' },
  lualine_z = { 'location' },
}

local inactive_sections = {
  -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
  lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
}

return {
  {
    'nvim-lualine/lualine.nvim',
    opts = function()
      return {
        extensions = { 'neo-tree', 'nvim-dap-ui', 'quickfix', 'toggleterm' },
        inactive_sections = {},
        -- inactive_sections = inactive_sections,
        options = options,
        sections = {},
        -- sections = sections,
        tabline = sections,
      }
    end,
  },
}
