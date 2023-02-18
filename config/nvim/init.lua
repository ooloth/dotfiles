local config = 'lazyvim' -- 'mine' or 'lazyvim'

if config == 'lazyvim' then
  require('config.lazy')
else
  require('mu.plugins-setup') -- should be first
  require('mu.colorscheme')
  require('mu.keymaps')
  require('mu.options')
  require('mu.plugins.autopairs')
  require('mu.plugins.comment')
  require('mu.plugins.gitsigns')
  require('mu.plugins.lsp.lspsaga') -- set up before mason
  require('mu.plugins.lsp.mason')
  require('mu.plugins.lualine')
  require('mu.plugins.nvim-cmp')
  require('mu.plugins.nvim-tree')
  -- require('mu.plugins.telescope')
  require('mu.plugins.treesitter')
  require('mu.plugins.trouble')
  require('mu.plugins.vim-floaterm')
end
