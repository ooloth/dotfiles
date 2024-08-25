--  TODO: testing: unittest?
--  TODO: https://www.lazyvim.org/extras/lang/python
--  TODO: https://www.lazyvim.org/extras/formatting/black

local extend = require('util').extend
local inspect = require('util').inspect
local is_installed_in_venv = require('util.prefer_venv').is_installed_in_venv
local prefer_venv_executable = require('util.prefer_venv').prefer_venv_executable

-- Help debugger find current project's local (not pip) modules:
-- https://stackoverflow.com/a/63271966/8802485
vim.env.PYTHONPATH = vim.fn.getcwd()

-- TODO: automate creation of the pynvim venv and the installation of pynvim, debugpy + CopilotChat's pip deps during mac setup
-- get python executable where pynvim is installed for running remote plugins written in python (see :h provider-python)
-- see: https://github.com/neovim/pynvim/issues/498
-- see: https://github.com/neovim/pynvim/issues/16#issuecomment-152417012
local pynvim_python = vim.env.HOME .. '/.pyenv/versions/pynvim/bin/python'
vim.g.python3_host_prog = pynvim_python

-- get the python executable from the project venv (if active) for dap and neotest
local python = prefer_venv_executable('python')

-- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/black.lua
local get_formatter_options = function(formatter)
  local formatter_options = require('conform.formatters.' .. formatter)
  local executable = formatter == 'ruff_format' and 'ruff' or formatter
  formatter_options.command = prefer_venv_executable(executable)
  formatter_options.condition = function()
    return is_installed_in_venv(executable)
  end
  return formatter_options
end

local get_linters_in_venv = function(linters)
  local linters_in_venv = vim.tbl_filter(function(linter)
    local executable = linter == 'ruff_lint' and 'ruff' or linter
    return is_installed_in_venv(executable)
  end, linters)

  return linters_in_venv
end

local get_linter_options = function(linter)
  local linter_options = require('lint.linters.' .. linter)
  linter_options.cmd = prefer_venv_executable(linter)
  return linter_options
end

return {
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'black', 'flake8', 'isort', 'mypy', 'pyright', 'ruff', 'ruff-lsp', 'yapf' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'python', 'requirements' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    -- see: https://www.lazyvim.org/extras/lang/python#nvim-lspconfig
    opts = {
      servers = {
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pylsp
        -- pylsp = {
        --   settings = {
        --     pylsp = {
        --       plugins = {
        --         autopep8 = { enabled = false },
        --       },
        --     },
        --   },
        -- },
        -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pyright
        pyright = {
          capabilities = (function()
            -- Disable Pyright diagnostics (use flake8 or ruff for linting):
            -- see: https://www.reddit.com/r/neovim/comments/11k5but/how_to_disable_pyright_diagnostics/
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.publishDiagnostics.tagSupport.valueSet = { 2 }
            return capabilities
          end)(),
          settings = {
            -- see: https://microsoft.github.io/pyright/#/settings
            python = {
              analysis = {
                -- diagnosticMode = 'workspace',
                diagnosticSeverityOverrides = {
                  reportUnusedVariable = 'off', -- use ruff or flake8 for linting (diagnostics)
                },
                typeCheckingMode = 'off', -- use mypy for type-checking
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
              -- Disable Ruff's hover in favor of Pyright's
              client.server_capabilities.hoverProvider = false
            end
          end)
        end,
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = { python = { 'isort', 'black', 'ruff_format', 'yapf' } },
      -- stylua: ignore
      formatters = {
        black = function() return get_formatter_options('black') end,
        isort = function() return get_formatter_options('isort') end,
        ruff_format = function() return get_formatter_options('ruff_format') end,
        yapf = function() return get_formatter_options('yapf') end,
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    -- see: https://www.lazyvim.org/plugins/linting#nvim-lint
    opts = {
      linters_by_ft = {
        python = get_linters_in_venv({ 'flake8', 'mypy', 'ruff_lint' }),
      },
      -- stylua: ignore
      linters = {
        flake8 = function() return get_linter_options('flake8') end,
        mypy = function() return get_linter_options('mypy') end,
        ruff_lint = function() return get_linter_options('ruff') end,
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'mfussenegger/nvim-dap-python',
      -- stylua: ignore
      keys = {
        { "<leader>dPt", function() require('dap-python').test_method() end, desc = "Debug Method", ft = "python" },
        { "<leader>dPc", function() require('dap-python').test_class() end, desc = "Debug Class", ft = "python" },
      },
      config = function()
        -- use the debugpy installed in the pynvim venv so I don't have to install it in every project's venv:
        local pynvim_debugpy_python = vim.env.HOME .. '/.pyenv/versions/pynvim/bin/debugpy' .. '/venv/bin/python'

        require('dap-python').setup(pynvim_debugpy_python, { include_configs = true, pythonPath = python })
      end,
    },
  },

  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-python',
    },
    opts = {
      adapters = {
        ['neotest-python'] = {
          -- see: https://github.com/nvim-neotest/neotest-python
          args = { '--log-level', 'DEBUG', '--quiet' },
          dap = {
            -- see: https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings#launchattach-settings
            console = 'integratedTerminal',
            justMyCode = true,
          },
          python = python,
        },
      },
    },
  },
}
