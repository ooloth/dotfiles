return {}

-- install the formatter (see: https://mason-registry.dev/registry/list)
-- require('mason-tool-installer').setup({ ensure_installed = { 'buf' } })
-- vim.api.nvim_command('MasonToolsInstall')

-- -- -- linting (see: https://github.com/mfussenegger/nvim-lint#usage)
-- -- require('lint').linters_by_ft.protobuf = { 'buf_lint' }
-- --
-- -- formatting (see: https://github.com/stevearc/conform.nvim#options)
-- require('conform').formatters_by_ft.protobuf = { 'buf' }
--
--  TODO: lsp (not yet; see: https://github.com/bufbuild/buf/pull/2662)
--  TODO: treesitter
