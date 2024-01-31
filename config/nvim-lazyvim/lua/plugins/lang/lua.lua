-- install the formatter
require('mason-tool-installer').setup({ ensure_installed = { 'lua_ls', 'stylua' } })
vim.api.nvim_command('MasonToolsInstall')

-- lsp (see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#lua_ls)
require('lspconfig').lua_ls.setup({
  settings = {
    -- TODO: prefer local version over mason version?
    -- see: https://www.lazyvim.org/plugins/lsp#nvim-lspconfig
    -- see: https://luals.github.io/wiki/settings/
    Lua = {
      completion = {
        callSnippet = 'Replace',
      },
      runtime = {
        -- tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      workspace = {
        checkThirdParty = false,
        -- make the server aware of Neovim runtime files
        library = {
          vim.env.VIMRUNTIME,
        },
      },
    },
  },
})

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').formatters_by_ft.lua = { 'stylua' }

--  TODO: treesitter
--  TODO: linting
--  TODO: dap?
