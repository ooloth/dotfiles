-- TODO: automatically set up all servers installed by mason (instead of doing it separately)
local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
if not lspconfig_ok then
  return
end

local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if not cmp_nvim_lsp_ok then
  return
end

local typescript_ok, typescript = pcall(require, 'typescript')
if not typescript_ok then
  return
end

local which_key_ok, wk = pcall(require, 'which-key')
if not which_key_ok then
  return
end

-- enable lsp keymaps only when an lsp server is attached
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- set lsp keymaps (non-leader key)
  vim.keymap.set('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', opts) -- jump to previous diagnostic in buffer
  vim.keymap.set('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', opts) -- jump to next diagnostic in buffer
  vim.keymap.set('n', 'gd', '<cmd>Lspsaga peek_definition<CR>', opts) -- see definition and make edits in window
  vim.keymap.set('n', 'gf', '<cmd>Lspsaga lsp_finder<CR>', opts) -- show definition, references
  vim.keymap.set('n', 'gh', '<cmd>Lspsaga hover_doc<CR>', opts) -- show documentation for what is under cursor
  vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<CR>', opts) -- show documentation for what is under cursor

  -- set lsp keymaps (leader key)
  wk.register({
    f = {
      d = { '<cmd>Telescope diagnostics bufnr=0<cr>', 'diagnostics (buffer)' },
      D = { '<cmd>Telescope diagnostics<cr>', 'diagnostics (project)' },
    },
    l = {
      name = 'lsp',
      a = { '<cmd>Lspsaga code_action<cr>', 'action' },
      d = { '<cmd>Lspsaga show_cursor_diagnostics<cr>', 'diagnostics for cursor' },
      D = { '<cmd>Lspsaga show_line_diagnostics<cr>', 'diagnostics for line' },
      i = { '<cmd>LspInfo<cr>', 'Lsp Info' },
      rs = { '<cmd>Lspsaga rename<cr>', 'rename symbol under cursor' },
      R = { '<cmd>LspRestart<cr>', 'restart' },
    },
  }, { buffer = bufnr, prefix = '<leader>' })

  -- autofix eslint issues on save
  if client.name == 'eslint' then
    vim.cmd([[
      autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js EslintFixAll
    ]])
  end

  -- set typescript-specific lsp keymaps
  if client.name == 'tsserver' then
    wk.register({
      l = {
        rf = { '<cmd>TypescriptRenameFile<cr>', 'rename file' }, -- TODO: confirm if this works
      },
    }, { buffer = bufnr, prefix = '<leader>' })
  end
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
local signs = { Error = ' ', Warn = ' ', Hint = 'ﴞ ', Info = ' ' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end

-- configure css server
lspconfig['cssls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- configure emmet language server
lspconfig['emmet_ls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { 'css', 'html', 'javascriptreact', 'less', 'sass', 'scss', 'svelte', 'typescriptreact' },
})

-- configure eslint server (adds ability to auto-fix issues on save)
-- See: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#eslint
-- See: https://github.com/jose-elias-alvarez/null-ls.nvim/discussions/824#discussioncomment-3796550
lspconfig['eslint'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- configure html server
lspconfig['html'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

lspconfig['jsonls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- configure python server
lspconfig['pyright'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  -- See: https://github.com/microsoft/pyright/blob/0a18d907ce8a5746b2470b7435ec77bf6ebc7d81/packages/vscode-pyright/package.json#L118
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'off', -- using pyright for lsp but mypy for type-checking
        useLibraryCodeForTypes = true,
      },
      disableOrganizeImports = true, -- using isort for import sorting
    },
  },
})

lspconfig['remark_ls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- configure lua server (with special settings)
lspconfig['sumneko_lua'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = { -- custom settings for lua
    Lua = {
      -- make the language server recognize "vim" global
      diagnostics = {
        globals = { 'require', 'pcall', 'vim' },
      },
      workspace = {
        -- make language server aware of runtime files
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.stdpath('config') .. '/lua'] = true,
        },
      },
    },
  },
})

-- TODO: only attach if tailwindcss is installed in project
lspconfig['tailwindcss'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- configure typescript server with jose-elias-alvarez/typescript.nvim plugin
typescript.setup({
  server = {
    capabilities = capabilities,
    on_attach = on_attach,
  },
})

lspconfig['yamlls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
