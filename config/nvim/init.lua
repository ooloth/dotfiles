require('mu.plugins-setup') -- should be first
require('mu.core.colorscheme')
require('mu.core.keymaps')
require('mu.core.options')
require('mu.plugins.comment')
require('mu.plugins.lsp.mason') -- set up before lsp-config
require('mu.plugins.lsp.lsp-saga') -- set up before lsp-config
require('mu.plugins.lsp.lsp-config') -- set up after mason + lsp-saga
require('mu.plugins.lsp.null-ls') -- set up after mason + lsp-saga
require('mu.plugins.lualine')
require('mu.plugins.nvim-cmp')
require('mu.plugins.nvim-tree')
require('mu.plugins.telescope')
