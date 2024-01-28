-- install the formatters
require('mason-tool-installer').setup({ ensure_installed = { 'black', 'isort', 'ruff_format' } })
vim.api.nvim_command('MasonToolsInstall')

