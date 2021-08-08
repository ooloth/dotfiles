local set_keymap = require('utils').set_keymap
local nvim_set_keymap = require('utils').nvim_set_keymap
local try_require = require('utils').try_require

local cmd = vim.cmd

------------------------------------
-- Colemak Mod-DH keyboard layout --
------------------------------------

-- m -> h
set_keymap('', 'm', 'h')
set_keymap('', 'M', 'H')
set_keymap('', 'gm', 'gh')

-- n -> j
set_keymap('', 'n', 'j')
set_keymap('', 'N', 'J')
set_keymap('', 'gn', 'gj')

-- e -> k
set_keymap('', 'e', 'k')
set_keymap('', 'E', 'K')

-- i -> l
set_keymap('', 'i', 'l')
set_keymap('', 'I', 'L')

-- h -> i
set_keymap('', 'h', 'i')
set_keymap('', 'H', 'I')

-- j -> n
set_keymap('', 'j', 'n')
set_keymap('', 'J', 'N')
set_keymap('', 'gj', 'gn')

-- k -> m
set_keymap('', 'k', 'm')
set_keymap('', 'K', 'M')
set_keymap('', 'gk', 'gm')

-- l -> e
set_keymap('', 'l', 'e')
set_keymap('', 'L', 'E')

-- Easily exit help windows with Esc or q
cmd([[
  autocmd Filetype help nmap <buffer> <Esc> :q<CR>
  autocmd Filetype help nmap <buffer> q :q<CR>
]])

---------
-- LSP --
---------

local opts = { noremap=true, silent=true }

-- See `:help vim.lsp.*` for documentation on any of the below functions
set_keymap('n', 'ga', '<cmd>Telescope lsp_code_actions<cr>', opts)
set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
set_keymap("n", "gf", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
-- set_keymap("n", "gf", "<cmd>silent FormatWrite<cr>", opts)
set_keymap('n', 'gh', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
set_keymap('n', 'gm', '<cmd>Telescope marks<CR>', opts)
set_keymap('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
set_keymap('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)

-- function! s:show_documentation()
--   if (index(['vim','help'], &filetype) >= 0)
--     execute 'h '.expand('<cword>')
--   else
--     exec ":lua vim.lsp.buf.hover()"
--   endif
-- endfunction

-- " Get details on hover
-- noremap gh :call <SID>show_documentation()<CR>

-----------
-- Compe --
-----------

vim.cmd([[
  inoremap <silent><expr> <C-Space> compe#complete()
  inoremap <silent><expr> <CR>      compe#confirm(luaeval("require 'nvim-autopairs'.autopairs_cr()"))
  inoremap <silent><expr> <C-e>     compe#close('<C-e>')
  inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
  inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
]])

-- -- moving
-- set_keymap('i', '<c-a>', '<Esc>I')
-- set_keymap('i', '<c-e>', '<End>')

-- -- editing
set_keymap('n', 'Y', 'y$') -- make Y behave like D and C by yanking remainder of line only
-- set_keymap('n', '<a-Up>', '<cmd>m .-2<cr>')
-- set_keymap('n', '<a-Down>', '<cmd>m .+1<cr>')
-- set_keymap('i', '<c-d>', '<Esc>ddi')

-- -- splits
-- set_keymap('n', '<leader>s', '<c-w>w')
-- set_keymap('n', '<leader>j', '<c-w>j')
-- set_keymap('n', '<leader>k', '<c-w>k')
-- set_keymap('n', '<leader>h', '<c-w>h')
-- set_keymap('n', '<leader>l', '<c-w>l')

-- -- tab
-- set_keymap('n', '<s-Tab>', 'gT')
-- set_keymap('n', '<Tab>', 'gt')
-- set_keymap('n', '<leader>t[', '<cmd>tabmove -1<cr>')
-- set_keymap('n', '<leader>t]', '<cmd>tabmove +1<cr>')
-- set_keymap('n', '<leader>1', '1gt')
-- set_keymap('n', '<leader>2', '2gt')
-- set_keymap('n', '<leader>3', '3gt')
-- set_keymap('n', '<leader>4', '4gt')
-- set_keymap('n', '<leader>5', '5gt')
-- set_keymap('n', '<leader>6', '6gt')
-- set_keymap('n', '<leader>7', '7gt')
-- set_keymap('n', '<leader>8', '8gt')
-- set_keymap('n', '<leader>9', '9gt')
-- set_keymap('n', '<leader>0', '<cmd>tablast<cr>')

-- -- buf
-- set_keymap('n', '<leader>[', 'bprev')
-- set_keymap('n', '<leader>]', 'bnext')

-- -- quickfix
-- set_keymap('n', '<leader>cc', '<cmd>cclose<cr>')
-- set_keymap('n', '<leader>;', '<cmd>cprev<cr>')
-- set_keymap('n', '<leader>\'', '<cmd>cnext<cr>')

-- -- command
-- set_keymap('c', '<c-a>', '<Home>')
-- set_keymap('c', '<c-e>', '<End>')

-- -- LSP
-- set_keymap('n', '<leader>ld', '<cmd>lua vim.lsp.buf.definition()<cr>')
-- set_keymap('n', '<leader>lD', '<cmd>lua vim.lsp.buf.declaration()<cr>')
-- set_keymap('n', '<leader>lt', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
-- set_keymap('n', '<leader>li', '<cmd>lua vim.lsp.buf.implementation()<cr>')
-- set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')
-- set_keymap('n', 'U', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
-- set_keymap('n', '<leader>lr', '<cmd>lua vim.lsp.buf.references()<cr>')
-- set_keymap('n', '<leader>ls', '<cmd>lua vim.lsp.buf.document_symbol()<cr>')
-- set_keymap('n', '<leader>lS', '<cmd>lua vim.lsp.buf.workspace_symbol()<cr>')
-- set_keymap('n', '<leader>lR', '<cmd>lua vim.lsp.buf.rename()<cr>')
-- set_keymap('n', '<leader>lf', '<cmd>lua vim.lsp.buf.formatting()<cr>')

-- -- plug manager
-- set_keymap('n', '<leader>pi', '<cmd>PaqInstall<cr>')
-- set_keymap('n', '<leader>pu', '<cmd>PaqUpdate<cr>')
-- set_keymap('n', '<leader>pc', '<cmd>PaqClean<cr>')

-- -- comment
-- nvim_set_keymap('i', '<c-_>', '<Esc><Plug>CommentaryLine', {})
-- nvim_set_keymap('n', '<c-_>', '<Plug>CommentaryLine', {})
-- nvim_set_keymap('v', '<c-_>', '<Plug>Commentary', {})

-- -- git-blame
-- set_keymap('n', '<leader>gb', '<cmd>GitBlameToggle<cr>')

-- -- dial.nvim
-- nvim_set_keymap('n', '<c-a>', '<Plug>(dial-increment)', {})
-- nvim_set_keymap('n', '<c-x>', '<Plug>(dial-decrement)', {})
-- nvim_set_keymap('v', '<c-a>', '<Plug>(dial-increment)', {})
-- nvim_set_keymap('v', '<c-x>', '<Plug>(dial-decrement)', {})
-- nvim_set_keymap('v', 'g<c-a>', '<Plug>(dial-increment-additional)', {})
-- nvim_set_keymap('v', 'g<c-x>', '<Plug>(dial-decrement-additional)', {})

-- -- hop.nvim
-- set_keymap('n', 's', '<cmd>HopChar2<cr>')
-- set_keymap('n', 'S', '<cmd>HopWord<cr>')
-- set_keymap('n', '<c-h>', '<cmd>HopLine<cr>')

-------------------------
-- Leader key mappings --
-------------------------

try_require('plugins.which-key')
