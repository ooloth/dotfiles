local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'astro-language-server', 'prettier' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- NOTE: linting comes from eslint-lsp (which already includes vue files by default)
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#astro
        astro = {},
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      -- see: https://github.com/virchau13/tree-sitter-astro/#troubleshooting
      extend(opts.ensure_installed, { 'astro', 'css', 'typescript', 'tsx' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      -- Also need to install prettier-plugin-astro in project
      -- see: https://github.com/withastro/prettier-plugin-astro#installation
      extend(opts.formatters_by_ft, { astro = { 'prettier' } })
    end,
  },
}
