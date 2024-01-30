-- install everything we need (see: https://mason-registry.dev/registry/list)
require('mason-tool-installer').setup({ ensure_installed = { 'terraform_fmt', 'terraformls' } })
vim.api.nvim_command('MasonToolsInstall')

-- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#terraformls
require('lspconfig').terraformls.setup({})

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters_by_ft = {
    terraform = { 'terraform_fmt' },
    ['terraform-vars'] = { 'terraform_fmt' },
  },
})

--  TODO: treesitter?
--  TODO: linting?
