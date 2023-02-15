local options = {
  component_separators = '',
  -- disabled_filetypes = {},
  globalstatus = true,
  section_separators = '',
  theme = 'dracula-nvim',
}

local sections = {
  lualine_a = { 'mode' },
  lualine_b = { 'branch', 'diff', 'diagnostics' },
  -- the larger the shorting_target number, the sooner the file path abbreviates
  -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
  lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
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

local python_sections = {
  lualine_a = { 'mode' },
  lualine_b = { 'branch', 'diff', 'diagnostics' },
  lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
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
    event = 'VeryLazy',
    opts = function()
      return {
        extensions = { 'fugitive', 'nvim-tree', 'quickfix', python_extension },
        options = options,
        sections = sections,
        inactive_sections = inactive_sections,
      }
    end,
  },
}
