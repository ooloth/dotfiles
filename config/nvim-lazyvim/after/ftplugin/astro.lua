-- install everything we need (see: https://mason-registry.dev/registry/list)
require('mason-tool-installer').setup({ ensure_installed = { 'astro' } })
vim.api.nvim_command('MasonToolsInstall')

-- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#astro
require('lspconfig').astro.setup({})

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    -- Also need to install prettier-plugin-astro in project
    -- see: https://github.com/withastro/prettier-plugin-astro#installation
    astro = { 'prettier' },
  },
})

--  TODO: treesitter
--  TODO: linting
--  TODO: dap?
--
-- TODO: https://github.com/wuelnerdotexe/vim-astro
-- TODO: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#astro
-- TODO: https://github.com/virchau13/tree-sitter-astro
