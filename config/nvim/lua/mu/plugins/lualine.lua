local status, lualine = pcall(require, 'lualine') -- import lualine plugin safely
if not status then
  return
end

lualine.setup({
  options = {
    theme = 'dracula-nvim',
  },
})
