-- TODO: https://www.lazyvim.org/extras/lang/go
-- TODO: lsp
-- TODO: treesitter
-- TODO: linting
-- TODO: dap

return {}

-- install all the formatters
-- require('mason-tool-installer').setup({ ensure_installed = { 'gofumpt', 'goimports', 'gci' } })
-- vim.api.nvim_command('MasonToolsInstall')

-- -- formatting (see: https://github.com/stevearc/conform.nvim#setup)
-- require('conform').setup({
--   formatters_by_ft = {
--     go = { 'gofumpt', 'goimports', 'gci' },
--   },
-- })
