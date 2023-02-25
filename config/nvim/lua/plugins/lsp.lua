return {
  --------------
  -- LSP SAGA --
  --------------
  {
    'glepnir/lspsaga.nvim',
    dependencies = {
      { 'nvim-tree/nvim-web-devicons' },
      { 'nvim-treesitter/nvim-treesitter' }, -- please make sure you install markdown and markdown_inline parsers
    },
    event = 'BufRead',
    keys = function()
      return {
        { '[d', '<cmd>Lspsaga diagnostic_jump_prev<cr>', desc = 'Previous diagnostic' },
        { ']d', '<cmd>Lspsaga diagnostic_jump_next<cr>', desc = 'Next diagnostic' },
        { 'ga', '<cmd>Lspsaga code_action<cr>', desc = 'Code actions' },
        { 'gd', '<cmd>Lspsaga lsp_finder<cr>', desc = 'Definition, references & implentations' },
        { 'gD', '<cmd>Lspsaga goto_definition<cr>', desc = 'Go to definition' },
        { 'gh', '<cmd>Lspsaga hover_doc<cr>', desc = 'Hover' },
        { 'go', '<cmd>Lspsaga outline<cr>', desc = 'Outline' },
        { 'gp', '<cmd>Lspsaga show_line_diagnostics<cr>', desc = 'Problems (line)' },
        { 'gt', '<cmd>Lspsaga goto_type_definition<cr>', desc = 'Go to type definition' },
        { 'R', '<cmd>LspRestart<cr>', desc = 'Restart LSP servers' },
        { 'K', '<cmd>Lspsaga hover_doc<cr>', desc = 'Hover' },
        { '<leader>r', '<cmd>Lspsaga rename<cr>', desc = 'Rename symbol' },
      }
    end,
    opts = {
      code_action = {
        keys = {
          quit = { 'q', '<esc>' },
          exec = '<CR>',
        },
      },
      diagnostic = {
        max_width = 0.99,
        keys = { quit = '<esc>' },
      },
      finder = {
        max_height = 0.99,
        keys = {
          jump_to = 'p',
          edit = { 'o', '<CR>' },
          vsplit = 'v',
          tabe = 't',
        },
      },
      hover = { max_width = 0.99 },
      lightbulb = { enable = false },
      outline = {
        win_position = 'right',
        win_with = '',
        win_width = 50,
        show_detail = true,
        auto_preview = true,
        auto_refresh = true,
        auto_close = true,
        custom_sort = nil,
        keys = {
          jump = 'o',
          expand_collapse = 'u',
          quit = '<esc>',
        },
      },
      rename = {
        quit = '<C-c>',
        in_select = false,
      },
      scroll_preview = { scroll_down = '<C-d>', scroll_up = '<C-u>' },
      symbol_in_winbar = { enable = false },
      ui = { border = 'rounded' },
    },
  },

  --------------------------------------
  -- 1. CUSTOMIZE LSP SERVER SETTINGS --
  --------------------------------------
  {
    'neovim/nvim-lspconfig',
    init = function()
      local keys = require('lazyvim.plugins.lsp.keymaps').get()
      -- disable default keymaps
      -- see: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
      keys[#keys + 1] = { ']d', false }
      keys[#keys + 1] = { '[d', false }
      keys[#keys + 1] = { 'gd', false }
      keys[#keys + 1] = { 'gD', false }
      keys[#keys + 1] = { 'gt', false }
      keys[#keys + 1] = { 'K', false }
      keys[#keys + 1] = { '<leader>ca', mode = { 'n', 'v' }, false }
      keys[#keys + 1] = { '<leader>cf', false }
      keys[#keys + 1] = { '<leader>cf', mode = { 'v' }, false }
    end,
    -- see: https://www.lazyvim.org/plugins/lsp#nvim-lspconfig
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        float = { border = 'rounded', source = true },
      },
      -- LSP Server Settings
      servers = {
        bashls = {},
        cssls = {},
        cssmodules_ls = {},
        dockerls = {},
        emmet_ls = {},
        eslint = {
          settings = {
            -- helpful when eslintrc is in a subfolder
            workingDirectory = { mode = 'auto' },
          },
        },
        html = {},
        jsonls = {},
        lua_ls = {},
        marksman = {},
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
        -- TODO: only load if used by project
        tailwindcss = {},
        terraformls = {},
        tsserver = {},
        yamlls = {},
      },
      setup = {
        eslint = function()
          vim.cmd([[
            autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js EslintFixAll
          ]])
        end,
      },
    },
  },

  --------------------------------------------------
  -- 3. DEFINE LINTERS & FORMATTERS USING NULL-LS --
  --------------------------------------------------
  {
    'jose-elias-alvarez/null-ls.nvim',
    opts = function() -- replace all default opts
      local nls = require('null-ls')
      return {
        -- formatters & linters mason will automatically install + set up below
        sources = {
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#code-actions
          nls.builtins.code_actions.proselint,

          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#diagnostics
          nls.builtins.diagnostics.flake8, -- python linter
          nls.builtins.diagnostics.markdownlint, -- markdown linter
          nls.builtins.diagnostics.mypy, -- python type-checker
          nls.builtins.diagnostics.proselint, -- prose linter
          nls.builtins.diagnostics.puglint, -- pug linter
          nls.builtins.diagnostics.tsc, -- ts type-checker
          nls.builtins.diagnostics.yamllint, -- yaml linter
          nls.builtins.diagnostics.zsh, -- zsh linter

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
    -- see: https://github.com/jay-babu/mason-null-ls.nvim#primary-source-of-truth-is-null-ls
    opts = {
      ensure_installed = nil, -- defined in null-ls sources above
      automatic_installation = true,
      automatic_setup = true,
    },
  },
}
