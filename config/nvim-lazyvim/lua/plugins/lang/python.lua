--  TODO: linting
--  TODO: types
--  TODO: testing
--  TODO: dap

-- see: https://www.lazyvim.org/extras/lang/python#nvim-lspconfig

local extend = require('util').extend
local is_installed_in_venv = require('util.prefer_venv').is_installed_in_venv
local prefer_venv_executable = require('util.prefer_venv').prefer_venv_executable

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'black', 'flake8', 'isort', 'mypy', 'pyright', 'ruff', 'ruff-lsp', 'yapf' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pyright
        pyright = {
          settings = {
            -- see: https://microsoft.github.io/pyright/#/settings
            python = {
              analysis = {
                diagnosticMode = 'workspace',
                typeCheckingMode = 'off', -- use pyright for lsp but mypy for type-checking
                useLibraryCodeForTypes = true,
              },
              disableOrganizeImports = true, -- use ruff or isort for import sorting
            },
          },
        },
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#ruff_lsp
        ruff_lsp = {},
      },
      setup = {
        ruff_lsp = function()
          require('lazyvim.util').lsp.on_attach(function(client, _)
            if client.name == 'ruff_lsp' then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end)
        end,
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'python' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = { python = { 'isort', 'black', 'ruff_format', 'yapf' } },
      formatters = {
        black = function()
          -- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/black.lua
          return {
            command = prefer_venv_executable('black'),
            condition = function()
              return is_installed_in_venv('black')
            end,
          }
        end,
        isort = function()
          return {
            command = prefer_venv_executable('isort'),
            condition = function()
              return is_installed_in_venv('isort')
            end,
          }
        end,
        ruff_format = function()
          return {
            command = prefer_venv_executable('ruff'),
            condition = function()
              return is_installed_in_venv('ruff')
            end,
          }
        end,
        yapf = function()
          return {
            command = prefer_venv_executable('yapf'),
            condition = function()
              return is_installed_in_venv('yapf')
            end,
          }
        end,
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    -- see: https://www.lazyvim.org/plugins/linting#nvim-lint
    opts = {
      linters_by_ft = {
        python = {
          -- 'flake8',
          'mypy',
          'ruff_lint',
        },
      },
      linters = {
        -- TODO: make condition work for uninstalled linters (it currently includes them)
        -- flake8 = function()
        --   return {
        --     cmd = prefer_venv_executable('flake8'),
        --     condition = function()
        --       return is_installed_in_venv('flake8')
        --     end,
        --   }
        -- end,
        mypy = function()
          return {
            cmd = prefer_venv_executable('mypy'),
            condition = function()
              return is_installed_in_venv('mypy')
            end,
          }
        end,
        ruff_lint = function()
          return {
            cmd = prefer_venv_executable('ruff'),
            condition = function()
              return is_installed_in_venv('ruff')
            end,
          }
        end,
      },
    },
  },
}

-- {lua require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')}
-- {
--     'mfussenegger/nvim-dap-python',
--     event = 'VeryLazy',
--     dependencies = { 'mfussenegger/nvim-dap' },
--     config = function()
--       require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
--       -- local dap = require('dap')
--       -- dap.adapters.python = {
--       --   type = 'executable',
--       --   command = 'python',
--       --   args = { '-m', 'debugpy.adapter' },
--       -- }
--       -- dap.configurations.python = {
--       --   {
--       --     type = 'python',
--       --     request = 'launch',
--       --     name = 'Launch file',
--       --     program = '${file}', -- This configuration will launch the current file if used.
--       --   },
--       -- }
--     end,
--   })
