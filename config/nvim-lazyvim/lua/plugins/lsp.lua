-- see: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-lazyvim/lua/plugins/lsp.lua
local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. '/**/bin/' .. executable_name, true, true)
    local executable_path = table.concat(paths, ', ')
    if executable_path ~= '' then
      vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. executable_path, 'None' } }, false, {})
      return executable_path
    end
  end

  local mason_registry = require('mason-registry')
  local mason_path = mason_registry.get_package(executable_name):get_install_path() .. '/venv/bin/' .. executable_name
  vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. mason_path, 'None' } }, false, {})
  return mason_path
end

return {
  {
    -- see: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',
    opts = {
      formatters = {
        -- black = {
        --   command = prefer_bin_from_venv('black'),
        -- },
        -- isort = {
        --   command = prefer_bin_from_venv('isort'),
        -- },
        -- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/prettier.lua
        prettier = {
          -- command = 'node_modules/.bin/prettier',
          require_cwd = true,
        },
        -- ruff_fix = {
        --   command = prefer_bin_from_venv('ruff'),
        -- },
        -- ruff_format = {
        --   command = prefer_bin_from_venv('ruff'),
        -- },
      },
      formatters_by_ft = {
        ['astro'] = { 'prettier' },
        ['css'] = { 'prettier' },
        ['go'] = { 'gofumpt', 'goimports', 'gci' },
        ['graphql'] = { 'prettier' },
        ['handlebars'] = { 'prettier' },
        ['html'] = { 'prettier' },
        ['javascript'] = { 'prettier' },
        ['javascriptreact'] = { 'prettier' },
        ['json'] = { 'prettier' },
        ['jsonc'] = { 'prettier' },
        ['less'] = { 'prettier' },
        ['lua'] = { 'stylua' },
        ['markdown'] = { 'prettier' },
        ['markdown.mdx'] = { 'prettier' },
        ['protobuf'] = { 'buf' },
        ['python '] = { 'ruff_fix', 'ruff_format' },
        ['rust '] = { 'rustfmt' },
        ['scss'] = { 'prettier' },
        ['typescript'] = { 'prettier' },
        ['typescriptreact'] = { 'prettier' },
        ['vue'] = { 'prettier' },
        ['xml'] = { 'prettier' },
        ['yaml'] = { 'prettier' },
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

  -- {
  --   'nvimtools/none-ls.nvim',
  --   keys = {
  --     {
  --       '<leader>xtp',
  --       function()
  --         -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/discussions/1258#discussioncomment-4245688
  --         require('null-ls').toggle('prettier')
  --       end,
  --       desc = 'Toggle prettier',
  --     },
  --   },
  --   opts = function() -- replace all default opts
  --     local nls = require('null-ls')
  --     return {
  --       -- root_dir = require('null-ls.utils').root_pattern('package.json', '.git'),
  --       -- formatters & linters mason will automatically install + set up below
  --       -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#code-actions
  --       sources = {
  --         nls.builtins.code_actions.proselint,
  --         nls.builtins.code_actions.shellcheck, -- bash linter
  --
  --         -- see: https://github.com/jose-elias-alvarez/typescript.nvim#setup-1
  --         require('typescript.extensions.null-ls.code-actions'),
  --
  --         nls.builtins.diagnostics.flake8, -- python linter
  --         nls.builtins.diagnostics.mypy, -- python type-checker
  --         nls.builtins.diagnostics.puglint, -- pug linter
  --         nls.builtins.diagnostics.shellcheck, -- bash linter
  --         nls.builtins.diagnostics.tsc, -- ts type-checker
  --         nls.builtins.diagnostics.zsh, -- zsh linter (basic compared to shellcheck for bash)
  --       },
  --     }
  --   end,
  -- },

  -- {
  --   'jay-babu/mason-null-ls.nvim',
  --   -- see: https://github.com/jay-babu/mason-null-ls.nvim#primary-source-of-truth-is-null-ls
  --   opts = {
  --     ensure_installed = nil, -- defined in null-ls sources above
  --     automatic_installation = true,
  --     automatic_setup = true,
  --   },
  -- },
}
