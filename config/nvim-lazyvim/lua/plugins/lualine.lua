local icons = require('lazyvim.config').icons

local options = {
  component_separators = '',
  -- disabled_filetypes = {},
  globalstatus = true,
  section_separators = '',
  theme = 'auto',
  -- theme = 'material-nvim',
  -- theme = 'dracula-nvim',
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
  lualine_x = { 'filetype' },
  lualine_y = { 'progress' },
  lualine_z = { 'location' },
}

local inactive_sections = {
  -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
  lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
}

local function get_venv()
  return vim.env.PYENV_VERSION and '(' .. vim.env.PYENV_VERSION .. ')' or ''
end

-- same as "sections" above, plus "get_venv"
local python_sections = {
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
    { 'filename', path = 1, shorting_target = 60, symbols = { modified = '', readonly = '', unnamed = '' } },
  },
  lualine_x = { 'filetype', get_venv }, -- the changed line
  lualine_y = { 'progress' },
  lualine_z = { 'location' },
}

-- show active venv next to filetypee in python files only
-- see: https://github.com/nvim-lualine/lualine.nvim#custom-extensions
local python_extension = {
  filetypes = { 'python' },
  options = options,
  sections = python_sections,
  inactive_sections = inactive_sections,
}

return {
  {
    'nvim-lualine/lualine.nvim',
    opts = function()
      return {
        extensions = { 'neo-tree', 'nvim-dap-ui', python_extension, 'quickfix', 'toggleterm' },
        options = options,
        sections = sections,
        inactive_sections = inactive_sections,
      }
    end,
  },
}
