local setup, dracula = pcall(require, 'dracula') -- import comment plugin safely
if not setup then
  return
end

-- See: https://github.com/Mofiqul/dracula.nvim#-configuration
dracula.setup({
  -- italic_comment = true,
  lualine_bg_color = '#282A36',
})

local status, _ = pcall(vim.cmd, 'colorscheme dracula')
if not status then
  print('Colorscheme not found!')
  return
end
