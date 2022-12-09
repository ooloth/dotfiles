-- import mason plugin safely
local mason_status, mason = pcall(require, 'mason')
if not mason_status then
  return
end

-- import mason-lspconfig plugin safely
local mason_lspconfig_status, mason_lspconfig = pcall(require, 'mason-lspconfig')
if not mason_lspconfig_status then
  return
end

-- import mason-null-ls plugin safely
local mason_null_ls_status, mason_null_ls = pcall(require, 'mason-null-ls')
if not mason_null_ls_status then
  return
end

-- enable mason
mason.setup()

mason_lspconfig.setup({
  -- list of servers for mason to install
  -- See: https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers
  ensure_installed = {
    'cssls',
    'emmet_ls',
    'eslint',
    'html',
    'jsonls',
    'pyright',
    'remark_ls',
    'sumneko_lua',
    'tailwindcss',
    'tsserver',
    'yamlls',
  },
  -- auto-install configured servers (with lspconfig)
  automatic_installation = true, -- not the same as ensure_installed
})
--
mason_null_ls.setup({
  -- list of formatters & linters for mason to install
  ensure_installed = {
    'eslint_d', -- ts/js linter
    'flake8', -- python linter
    'isort', -- python formatter
    'mypy', -- python linter
    'prettierd', -- ts/js formatter
    'stylua', -- lua formatter
  },
  -- auto-install configured formatters & linters (with null-ls)
  automatic_installation = true,
})
