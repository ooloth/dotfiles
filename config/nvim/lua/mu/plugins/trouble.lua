local trouble_ok, trouble = pcall(require, 'trouble')
if not trouble_ok then
  return
end

-- see: https://github.com/folke/trouble.nvim#%EF%B8%8F-configuration
trouble.setup({
  -- position = 'left',
  height = 15,
})
