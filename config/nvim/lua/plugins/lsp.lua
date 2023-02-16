return {

  --------------------------------------
  -- 1. CUSTOMIZE LSP SERVER SETTINGS --
  --------------------------------------
  {
    'neovim/nvim-lspconfig',
    opts = {
      -- LSP Server Settings
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                diagnosticMode = 'workspace',
                typeCheckingMode = 'off', -- using pyright for lsp but mypy for type-checking
                useLibraryCodeForTypes = true,
              },
              disableOrganizeImports = true, -- using isort for import sorting
            },
          },
        },
      },
    },
  },

  --------------------------------
  -- 2. SET UP MASON-LSPCONFIG --
  --------------------------------
  {
    'williamboman/mason-lspconfig.nvim',
    opts = function()
      return {
        automatic_installation = true,
        -- lsp servers mason will automatically install + set up below
        -- see: https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
        ensure_installed = {
          'bashls',
          'cssls',
          'cssmodules_ls',
          'dockerls',
          'emmet_ls',
          'eslint',
          'html',
          'jsonls',
          'lua_ls',
          'marksman',
          'pyright',
          'svelte',
          'tailwindcss',
          'terraformls',
          'tsserver',
          'yamlls',
        },
      }
    end,
  },

  --------------------------------------------------
  -- 3. DEFINE LINTERS & FORMATTERS USING NULL-LS --
  --------------------------------------------------
  {
    'jose-elias-alvarez/null-ls.nvim',
    opts = function()
      local nls = require('null-ls')
      return {
        -- formatters & linters mason will automatically install + set up below
        sources = {
          -- code actions providers
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#code-actions
          nls.builtins.code_actions.gitsigns,
          nls.builtins.code_actions.proselint,

          -- linters & type-checkers
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#diagnostics
          nls.builtins.diagnostics.flake8, -- python linter
          nls.builtins.diagnostics.markdownlint, -- markdown linter
          nls.builtins.diagnostics.mypy, -- python type-checker
          nls.builtins.diagnostics.proselint, -- prose linter
          nls.builtins.diagnostics.puglint, -- pug linter
          nls.builtins.diagnostics.tsc, -- ts type-checker
          nls.builtins.diagnostics.yamllint, -- yaml linter
          nls.builtins.diagnostics.zsh, -- zsh linter

          -- formatters
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#formatting
          -- formatting.beautysh, -- zsh/bash/sh (reenable when settings configurable)
          nls.builtins.formatting.black, -- python
          nls.builtins.formatting.isort, -- python
          nls.builtins.formatting.prettier, -- js/ts etc
          nls.builtins.formatting.shfmt, -- bash
          nls.builtins.formatting.stylua, -- lua
        },
      }
    end,
  },

  --------------------------------------------------------------------------
  -- 4. AUTOMATICALLY INSTALL + SET UP NULL-LS SOURCES WITH MASON-NULL-LS --
  --------------------------------------------------------------------------
  {
    'jay-babu/mason-null-ls.nvim',
    opts = {
      ensure_installed = nil, -- defined in null-ls sources above
      automatic_installation = true,
      automatic_setup = true,
    },
  },
}
