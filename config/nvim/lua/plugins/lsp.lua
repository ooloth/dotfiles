return {
  {
    'glepnir/lspsaga.nvim',
    event = 'BufRead',
    dependencies = {
      { 'nvim-tree/nvim-web-devicons' },
      { 'nvim-treesitter/nvim-treesitter' }, -- please make sure you install markdown and markdown_inline parsers
    },
    keys = function()
      return {
        { ']x', '<cmd>Lspsaga diagnostic_jump_next<cr>', desc = 'Next diagnostic' },
        { '[x', '<cmd>Lspsaga diagnostic_jump_prev<cr>', desc = 'Previous diagnostic' },
        { 'ga', '<cmd>Lspsaga code_action<cr>', desc = 'Code actions' },
        { 'gd', '<cmd>Lspsaga lsp_finder<cr>', desc = 'Definition, references & implentations' },
        { 'gD', '<cmd>Lspsaga goto_definition<cr>', desc = 'Go to definition' },
        { 'gh', '<cmd>Lspsaga hover_doc<cr>', desc = 'Hover' },
        { 'go', '<cmd>Lspsaga outline<cr>', desc = 'Outline' },
        { 'gt', '<cmd>Lspsaga goto_type_definition<cr>', desc = 'Go to type definition' },
        { '<leader>a', 'ga', desc = 'Actions', remap = true },
        { '<leader>xn', ']x', desc = 'Next diagnostic', remap = true },
        { '<leader>xp', '[x', desc = 'Previous diagnostic', remap = true },
      }
    end,
    opts = {
      code_action = {
        quit = { 'q', '<esc>' },
        keys = {
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

  {

    'williamboman/mason.nvim',
    keys = function() -- remove all keys
      return {}
    end,
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = { 'jose-elias-alvarez/typescript.nvim' },
    init = function()
      local keys = require('lazyvim.plugins.lsp.keymaps').get()
      -- see: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
      keys[#keys + 1] = { 'R', '<cmd>LspRestart<cr>', desc = 'Restart LSP servers' }
      keys[#keys + 1] = { '<leader>L', '<cmd>LspInfo<cr>', desc = 'LSP info' }
      keys[#keys + 1] = { '<leader>m', '<cmd>Mason<cr>', desc = 'Mason' }
      keys[#keys + 1] = { '<leader>n', '<cmd>NullLsInfo<cr>', desc = 'Null-LS info' }
      keys[#keys + 1] = { '<leader>rs', vim.lsp.buf.rename, desc = 'Rename symbol', has = 'rename' }
      keys[#keys + 1] = { ']d', false }
      keys[#keys + 1] = { '[d', false }
      keys[#keys + 1] = { 'gd', false }
      keys[#keys + 1] = { 'gD', false }
      keys[#keys + 1] = { 'gt', false }
      keys[#keys + 1] = { 'K', false }
      keys[#keys + 1] = { '<leader>ca', mode = { 'n', 'v' }, false }
      keys[#keys + 1] = { '<leader>cd', false }
      keys[#keys + 1] = { '<leader>cf', false }
      keys[#keys + 1] = { '<leader>cf', mode = { 'v' }, false }
      keys[#keys + 1] = { '<leader>cl', false }
      keys[#keys + 1] = { '<leader>co', false }
      keys[#keys + 1] = { '<leader>cr', false }
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
            -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
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
        tsserver = function(_, opts)
          require('typescript').setup({ server = opts })
          return true
        end,
      },
    },
  },

  {
    'jose-elias-alvarez/null-ls.nvim',
    keys = {
      {
        '<leader>xtp',
        function()
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/discussions/1258#discussioncomment-4245688
          require('null-ls').toggle('prettier')
        end,
        desc = 'Toggle prettier',
      },
    },
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
          -- nls.builtins.formatting.prettier.with({
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTIN_CONFIG.md#conditional-sources
          -- runtime_condition = function(utils)
          --   return utils.root_has_file({
          --     -- https://prettier.io/docs/en/configuration.html
          --     '.prettierrc',
          --     '.prettierrc.json',
          --     '.prettierrc.yml',
          --     '.prettierrc.yaml',
          --     '.prettierrc.json5',
          --     '.prettierrc.js',
          --     '.prettierrc.cjs',
          --     '.prettierrc.toml',
          --     'prettier.config.js',
          --     'prettier.config.cjs',
          --   })
          -- end,
          -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTIN_CONFIG.md#using-local-executables
          -- only_local = 'node_modules/.bin',
          -- root_dir = require('null-ls.utils').root_pattern('.prettierrc'),
          -- or require('null-ls.utils').root_pattern('.git'),
          -- runtime_condition = function(params)
          -- local utils = require('null-ls.utils')
          --
          -- local package_json_root = utils.root_pattern('package.json')(params.bufname)
          -- local git_root = utils.root_pattern('.git')(params.bufname)
          -- local root = package_json_root or git_root
          -- local root = package_json_root

          -- return root and utils.path.exists(utils.path.join(root, '.prettierrc'))
          --   return root
          --     and utils.root_has_file({
          --       -- https://prettier.io/docs/en/configuration.html
          --       '.prettierrc',
          --       '.prettierrc.json',
          --       '.prettierrc.yml',
          --       '.prettierrc.yaml',
          --       '.prettierrc.json5',
          --       '.prettierrc.js',
          --       '.prettierrc.cjs',
          --       '.prettierrc.toml',
          --       'prettier.config.js',
          --       'prettier.config.cjs',
          --     })
          -- end,
          -- }), -- js/ts etc

          nls.builtins.formatting.shfmt, -- bash
          nls.builtins.formatting.stylua, -- lua
        },
      }
    end,
  },

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
