require('mu.plugins.colorscheme.dracula') -- require is relative to init.lua

-- display correct colors when vim opened inside tmux
vim.cmd([[
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
]])

-- highlight MDX like MD
vim.cmd([[
  autocmd BufNewFile,BufRead *.mdx set filetype=markdown.mdx
]])
