--  TODO: lsp?
--  TODO: formatting?
--  TODO: linting?

return {
  -- {
  -- 'WhoIsSethDaniel/mason-tool-installer.nvim',
  --   opts = function(_, opts)
  --     extend(opts.ensure_installed, {})
  --   end,
  -- },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { 'vim', 'vimdoc' })
    end,
  },

  -- {
  --   'neovim/nvim-lspconfig',
  --   opts = {
  --     servers = {
  --     },
  --   },
  -- },

  -- {
  --   'stevearc/conform.nvim',
  --   opts = {
  --     formatters_by_ft = {},
  --   },
  -- },
}
