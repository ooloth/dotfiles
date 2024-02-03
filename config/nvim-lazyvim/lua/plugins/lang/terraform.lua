-- see: https://www.lazyvim.org/xtras/lang/terraform

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'terraform-ls', 'tflint' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- NOTE: linting comes from eslint-lsp (which already includes vue files by default)
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#bashls
        terraformls = {},
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'hcl', 'terraform' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      extend(opts.formatters_by_ft, {
        terraform = { 'terraform_fmt' },
        ['terraform-vars'] = { 'terraform_fmt' },
        tf = { 'terraform_fmt' },
      })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = function(_, opts)
      extend(opts.linters_by_ft, { terraform = { 'tflint' }, tf = { 'tflint' } })
    end,
  },
}
