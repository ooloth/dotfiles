-- TODO: lsp?
-- TODO: treesitter?
-- TODO: linting?
-- TODO: dap?

-- The LazyVim YAML extra is installed (includes lsp + treesitter):
-- https://www.lazyvim.org/extras/lang/yaml

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'bash-language-server', 'shellcheck', 'shfmt' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'bash' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      extend(opts.formatters_by_ft, { bash = { 'shfmt' }, sh = { 'shfmt' } })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = function(_, opts)
      extend(opts.linters_by_ft, { bash = { 'shellcheck' }, sh = { 'shellcheck' } })
    end,
  },
}
