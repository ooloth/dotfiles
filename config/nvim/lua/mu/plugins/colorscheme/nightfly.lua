local status, _ = pcall(vim.cmd, 'colorscheme nightfly')
if not status then
  print('Colorscheme not found!')
  return
end

-- style floating windows
-- See: https://github.com/bluz71/vim-nightfly-colors#nightflynormalfloat
vim.g.nightflyNormalFloat = true

-- separate windows with a thick line instead of a block
-- See: https://github.com/bluz71/vim-nightfly-colors#nightflywinseparator
vim.g.nightflyWinSeparator = 2
vim.opt.fillchars = {
  horiz = '━',
  horizup = '┻',
  horizdown = '┳',
  vert = '┃',
  vertleft = '┫',
  vertright = '┣',
  verthoriz = '╋',
}
