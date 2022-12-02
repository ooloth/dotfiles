local status, lualine = pcall(require, 'lualine') -- import lualine plugin safely
if not status then
  return
end

lualine.setup({
  options = {
    component_separators = '',
    globalstatus = true, -- have a single statusline instead of one for every window
    section_separators = '',
    theme = 'dracula-nvim',
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { 'filename' },
    lualine_x = { 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})
