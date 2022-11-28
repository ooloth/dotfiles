local try_require = require('utils').try_require

local cmd = vim.cmd
local opt = vim.opt
local has = vim.fn.has

-- syntax highlighting options
cmd('filetype plugin indent on')
cmd('syntax enable')

if not has('gui_running') then
    opt.t_Co = 256
end

if has('termguicolors') then
    opt.termguicolors = true
    cmd([[
      let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
      let &t_8b = "\\<Esc>[48;2;%lu;%lu;%lum"
    ]])
end

opt.re = 0 -- https://github.com/HerringtonDarkholme/yats.vim#config

-- highlight MDX like MD
cmd([[
  autocmd BufNewFile,BufRead *.mdx set filetype=markdown.mdx
]])

-- colorscheme
-- try_require('plugins.everforest')
-- try_require('plugins.gruvbox-material')
try_require('plugins.nord')
-- try_require('plugins.palenight')
