require('mu.plugins-setup') -- should be first
require('mu.keymaps')
require('mu.options')
require('mu.colorscheme')
require('mu.plugins.comment')
require('mu.plugins.lsp.mason') -- set up before lsp-config
require('mu.plugins.lsp.lsp-saga') -- set up before lsp-config
require('mu.plugins.lsp.lsp-config') -- set up after mason + lsp-saga
require('mu.plugins.lsp.null-ls') -- set up after mason + lsp-saga
require('mu.plugins.autopairs')
require('mu.plugins.auto-session')
require('mu.plugins.gitsigns')
require('mu.plugins.lualine')
require('mu.plugins.nvim-cmp')
require('mu.plugins.nvim-tree')
require('mu.plugins.telescope')
require('mu.plugins.treesitter')
-- require('mu.plugins.vim-startify')
