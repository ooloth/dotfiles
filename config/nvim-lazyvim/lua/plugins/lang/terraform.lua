--  TODO: treesitter?
--  TODO: linting?

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'terraform_fmt', 'terraformls' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      extend(opts.formatters_by_ft, {
        terraform = { 'terraform_fmt' },
        ['terraform-vars'] = { 'terraform_fmt' },
      })
    end,
  },
}
