vim.g.copilot_no_tab_map = true

vim.cmd([[
  " accept copilot suggestions with <cr> instead of <tab>
  imap <silent><script><expr> <cr> copilot#Accept("\<cr>")
]])

return {
  { 'github/copilot.vim' },
}
