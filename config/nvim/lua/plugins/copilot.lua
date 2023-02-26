vim.g.copilot_no_tab_map = true

vim.cmd([[
  imap <silent><script><expr> <cr> copilot#Accept("\<cr>")
  " imap <silent><script><expr> <c-j> copilot#Accept("\<cr>")
]])

return {
  { 'github/copilot.vim' },
}
