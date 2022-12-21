local lualine_ok, lualine = pcall(require, 'lualine')
if not lualine_ok then
  return
end

lualine.setup({
  options = {
    component_separators = '',
    section_separators = '',
    theme = 'dracula-nvim',
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    -- the larger the shorting_target number, the sooner the file path abbreviates
    -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
    lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
    lualine_x = { 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
  inactive_sections = {
    -- see: https://github.com/nvim-lualine/lualine.nvim#filename-component-options
    lualine_c = { { 'filename', path = 1, shorting_target = 100 } },
  },
})
