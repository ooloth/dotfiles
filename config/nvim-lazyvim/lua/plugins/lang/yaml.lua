-- The LazyVim YAML extra is installed (includes lsp + treesitter):
-- https://www.lazyvim.org/extras/lang/yaml

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'prettier', 'yaml-language-server' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      extend(opts.formatters_by_ft, { yaml = { 'prettier' } })
    end,
  },
}