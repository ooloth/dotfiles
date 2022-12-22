local lualine_ok, lualine = pcall(require, 'lualine')
if not lualine_ok then
  return
end

local function split(input, delimiter)
  local arr = {}
  string.gsub(input, '[^' .. delimiter .. ']+', function(w)
    table.insert(arr, w)
  end)
  return arr
end

-- see: https://github.com/nvim-lualine/lualine.nvim/issues/277#issuecomment-1337515821
local function get_venv()
  local venv = vim.env.VIRTUAL_ENV
  if venv then
    local params = split(venv, '/')
    -- see: https://scriptinghelpers.org/questions/75451/how-do-you-index-the-last-element-in-a-list
    return '(' .. params[#params] .. ')'
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
local venv_extension = { sections = python_sections, filetypes = { 'python' } }

lualine.setup({
  disabled_filetypes = {},
  extensions = { 'fugitive', 'nvim-tree', 'quickfix', venv_extension },
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
