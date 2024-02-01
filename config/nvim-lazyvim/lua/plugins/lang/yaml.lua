-- The LazyVim YAML extra is installed (includes lsp + treesitter):
-- https://www.lazyvim.org/extras/lang/yaml

return {
  {
    'williamboman/mason.nvim',
    opts = {
      -- see: https://mason-registry.dev/registry/list
      ensure_installed = { 'yaml-language-server' },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        -- see: https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
        yaml = { 'prettier' },
      },
    },
  },
}
