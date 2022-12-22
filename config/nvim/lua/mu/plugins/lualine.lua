local lualine_ok, lualine = pcall(require, 'lualine')
if not lualine_ok then
  return
end

local function get_venv()
  local venv = vim.env.PYENV_VERSION
  if venv then
    return '(' .. venv .. ')'
  else
    return ''
  end
end

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
local python_extension = { sections = python_sections, filetypes = { 'python' } }

lualine.setup({
  disabled_filetypes = {},
  extensions = { 'fugitive', 'nvim-tree', 'quickfix', python_extension },
  options = {
    component_separators = '',
    section_separators = '',
    theme = 'dracula-nvim',
  },
  sections = sections,
  inactive_sections = {
    -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
    lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
  },
})
