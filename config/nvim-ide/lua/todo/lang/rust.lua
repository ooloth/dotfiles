-- TODO: https://www.lazyvim.org/extras/lang/rust
-- TODO: lsp
-- TODO: treesitter
-- TODO: linting
-- TODO: dap?

return {}

-- install the formatter
-- require('mason-tool-installer').setup({ ensure_installed = { 'rustfmt' } })
-- vim.api.nvim_command('MasonToolsInstall')

-- -- formatting (see: https://github.com/stevearc/conform.nvim#setup)
-- require('conform').setup({
--   formatters_by_ft = {
--     rust = { 'rustfmt' },
--   },
-- })
