-- install the formatters
require('mason-tool-installer').setup({ ensure_installed = { 'black', 'isort', 'pyright', 'ruff_format' } })
vim.api.nvim_command('MasonToolsInstall')

-- lsp (see: https://github.com/neovim/nvim-lspconfig#quickstart)
require('lspconfig').pyright.setup({
  -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pyright
  settings = {
    -- TODO: prefer node modules version over mason version
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
  },
})

-- cache the result of the first prefer_bin_from_venv call for each executable
local cached_commands = {
  black = '',
  isort = '',
  ruff_format = '',
}

-- see: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-lazyvim/lua/plugins/lsp.lua
local function prefer_bin_from_venv(executable_name)
  -- use the cached result if it exists
  if cached_commands[executable_name] ~= '' then
    return cached_commands[executable_name]
  end

  -- otherwise, get the path to the node_modules binary (if it exists)
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. '/**/bin/' .. executable_name, true, true)
    local executable_path = table.concat(paths, ', ')
    if executable_path ~= '' then
      -- vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. executable_path, 'None' } }, false, {})
      cached_commands[executable_name] = executable_path
      return executable_path
    end
  end

  -- otherwise, get the path to the Mason binary
  local mason_registry = require('mason-registry')
  local mason_path = mason_registry.get_package(executable_name):get_install_path() .. '/venv/bin/' .. executable_name
  -- vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. mason_path, 'None' } }, false, {})
  cached_commands[executable_name] = mason_path
  return mason_path
end

--  TODO: linting

-- formatting (see: https://github.com/stevearc/conform.nvim#setup)
require('conform').setup({
  formatters = {
    black = function()
      -- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/black.lua
      return {
        command = prefer_bin_from_venv('black'),
        condition = function(ctx)
          return vim.fs.basename(ctx.filename) ~= 'README.md'
        end,
      }
    end,
    isort = function()
      return {
        command = prefer_bin_from_venv('isort'),
      }
    end,
    ruff_format = function()
      return {
        command = prefer_bin_from_venv('ruff'),
      }
    end,
  },
  formatters_by_ft = {
    --  TODO: choose formatter based on packages installed in virtualenv
    python = { 'isort', 'black', 'ruff_format' },
  },
})

--  TODO: lsp
--  TODO: treesitter
--  TODO: linting
--  TODO: dap

-- TODO: refactor to multiple after/ftplugin/python/*.lua files if this one gets too long?
