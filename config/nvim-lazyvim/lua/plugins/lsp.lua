return {
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
      keys[#keys + 1] = { '<leader>ic', '<cmd>ConformInfo<cr>', desc = 'Conform info' }
      keys[#keys + 1] = { '<leader>il', '<cmd>LspInfo<cr>', desc = 'LSP info' }
      keys[#keys + 1] = { '<leader>m', '<cmd>Mason<cr>', desc = 'Mason' }
      keys[#keys + 1] = { '<leader>rs', vim.lsp.buf.rename, desc = 'Rename symbol', has = 'rename' }
      keys[#keys + 1] = { ']d', false }
      keys[#keys + 1] = { '[d', false }
      keys[#keys + 1] = { 'gd', false }
      keys[#keys + 1] = { 'gD', false }
      keys[#keys + 1] = { 'gt', false }
      keys[#keys + 1] = { 'K', false }
      keys[#keys + 1] = { '<leader>ca', mode = { 'n', 'v' }, false }
      keys[#keys + 1] = { '<leader>cA', false }
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
        tsserver = {
          settings = {
            completions = {
              completeFunctionCalls = true,
            },
          },
        },
        yamlls = {},
      },
      setup = {
        eslint = function()
          vim.api.nvim_create_autocmd('BufWritePre', {
            callback = function(event)
              -- if eslint lsp server is active in buffer, automatically fix linting errors on save
              if require('lspconfig.util').get_active_client_by_name(event.buf, 'eslint') then
                vim.cmd('EslintFixAll')
              end
            end,
          })
        end,
        tsserver = function(_, opts)
          require('typescript').setup({ server = opts })
          return true
        end,
      },
    },
  },

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
        {
          '<leader>a',
          'ga',
          desc = 'Actions',
          remap = true,
        },
        {
          '<leader>xn',
          ']x',
          desc = 'Next diagnostic',
          remap = true,
        },
        {
          '<leader>xp',
          '[x',
          desc = 'Previous diagnostic',
          remap = true,
        },
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
}
