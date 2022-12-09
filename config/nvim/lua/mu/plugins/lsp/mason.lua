-- this file automatically installs + sets up all my lsp + null-ls servers

local mason_ok, mason = pcall(require, 'mason')
if not mason_ok then
  return
end

local mason_lspconfig_ok, mason_lspconfig = pcall(require, 'mason-lspconfig')
if not mason_lspconfig_ok then
  return
end

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

local null_ls_ok, null_ls = pcall(require, 'null-ls')
if not null_ls_ok then
  return
end

local mason_null_ls_ok, mason_null_ls = pcall(require, 'mason-null-ls')
if not mason_null_ls_ok then
  return
end

---------------------
-- 1. SET UP MASON --
---------------------

mason.setup()

--------------------------------
-- 2. SET UP MASON-LSPCONFIG --
--------------------------------

mason_lspconfig.setup({
  automatic_installation = true,
  -- lsp servers mason will automatically install + set up below
  -- See: https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers
  ensure_installed = {
    'bashls',
    'cssls',
    'cssmodules_ls',
    'dockerls',
    'emmet_ls',
    'eslint',
    'html',
    'jsonls',
    'marksman',
    'pyright',
    'sumneko_lua',
    'svelte',
    'tailwindcss',
    'terraformls',
    'tsserver',
    'yamlls',
  },
})

-------------------------------------------------
-- 3. SET UP LSP SERVERS WITH MASON-LSPCONFIG --
-------------------------------------------------

local on_attach = function(client, bufnr)
  -- only enable lsp keymaps when an lsp server is attached
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

-- this automatically sets up all installed lsp servers (including servers installed via :Mason)
-- :h mason-lspconfig.setup_handlers
mason_lspconfig.setup_handlers({
  -- default handler to be called for each installed server
  function(server_name)
    lspconfig[server_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end,

  ---------------
  -- OVERRIDES --
  ---------------
  -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

  ['pyright'] = function()
    lspconfig.pyright.setup({
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
  end,

  ['sumneko_lua'] = function()
    lspconfig.sumneko_lua.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = {
            -- if necessary, add to .luacheckrc "read_globals" as well
            globals = { 'pcall', 'read_globals', 'require', 'std', 'vim' },
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
  end,

  -- TODO: only attach to tailwindcss if tailwindcss is installed in project

  ['tsserver'] = function()
    -- set up tsserver with typescript.nvim plugin instead of lspconfig
    typescript.setup({
      server = {
        capabilities = capabilities,
        on_attach = on_attach,
      },
    })
  end,
})

--------------------------------------------------
-- 4. DEFINE LINTERS & FORMATTERS USING NULL-LS --
--------------------------------------------------

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

null_ls.setup({
  -- formatters & linters mason will automatically install + set up below
  sources = {
    -- linters & type-checkers
    diagnostics.eslint_d, -- js/ts linter
    diagnostics.flake8, -- python linter
    diagnostics.luacheck, -- lua linter
    diagnostics.markdownlint, -- markdown linter
    diagnostics.mypy, -- python type-checker
    diagnostics.proselint, -- prose linter
    diagnostics.puglint, -- pug linter
    diagnostics.tsc, -- ts type-checker
    diagnostics.yamllint, -- yaml linter
    diagnostics.zsh, -- zsh linter

    -- formatters
    formatting.beautysh, -- zsh/bash/sh
    formatting.isort, -- python
    formatting.prettierd, -- js/ts etc
    formatting.stylua, -- lua
    formatting.yapf, -- python
  },

  -- configure format on save
  on_attach = function(current_client, bufnr)
    if current_client.supports_method('textDocument/formatting') then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            filter = function(client)
              -- use null-ls instead of lsp server for formatting
              return client.name == 'null-ls'
            end,
            bufnr = bufnr,
          })
        end,
      })
    end
  end,

  -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/issues/429#issuecomment-992741722
  -- on_attach = function(client)
  --   if client.resolved_capabilities.document_formatting then
  --     vim.cmd('autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()')
  --   end
  -- end,
})

--------------------------------------------------------------------------
-- 5. AUTOMATICALLY INSTALL + SET UP NULL-LS SOURCES WITH MASON-NULL-LS --
--------------------------------------------------------------------------

-- see: https://github.com/jay-babu/mason-null-ls.nvim#primary-source-of-truth-is-null-ls
mason_null_ls.setup({
  ensure_installed = nil, -- defined in null-ls sources above
  automatic_installation = true,
  automatic_setup = true,
})
