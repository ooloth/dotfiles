--  TODO: https://www.lazyvim.org/extras/lang/markdown

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'markdownlint', 'marksman', 'vale-ls' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'markdown', 'markdown_inline', 'mermaid' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#marksman
        marksman = {},
        vale_ls = {},
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        markdown = { 'inject', 'prettier' },
        ['markdown.mdx'] = { 'prettier' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        markdown = { 'markdownlint' },
        -- NOTE: eslint_lsp already lints MDX files (install https://github.com/mdx-js/eslint-mdx in project)
      },
    },
  },
}
