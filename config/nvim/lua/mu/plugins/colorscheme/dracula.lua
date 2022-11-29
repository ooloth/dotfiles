local status, _ = pcall(vim.cmd, 'colorscheme dracula')
if not status then
  print('Colorscheme not found!')
  return
end
