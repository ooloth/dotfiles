return {}

-- -- -- install everything we need (see: https://mason-registry.dev/registry/list)
-- -- require('mason-tool-installer').setup({ ensure_installed = { 'dockerfile' } })
-- -- vim.api.nvim_command('MasonToolsInstall')
-- --
-- -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#dockerls
-- require('lspconfig').dockerls.setup({})
--
-- -- formatting (see: https://github.com/stevearc/conform.nvim#setup)
-- require('conform').setup({
--   formatters_by_ft = {
--     yaml = { 'prettier' },
--   },
-- })

--  TODO: formatting?
--  TODO: treesitter?
--  TODO: linting?
