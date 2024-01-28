-- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/prettier.lua
-- see: https://www.lazyvim.org/extras/formatting/prettier

local mason_registry = require('mason-registry')

-- cache the result of prefer_bin_from_node_modules function after the first call
local prettier_command = ''

local function prefer_bin_from_node_modules(executable_name)
  -- get the binary from node_modules if it exists
  local node_modules_path = vim.fn.getcwd() .. '/node_modules/.bin/' .. executable_name
  if vim.fn.executable(node_modules_path) == 1 then
    prettier_command = node_modules_path
    return node_modules_path
  end

  -- otherwise, get it from Mason
  local mason_path = mason_registry.get_package(executable_name):get_install_path()
    .. '/node_modules/.bin/'
    .. executable_name
  prettier_command = mason_path
  return mason_path
end

return {
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    opts = {
      ensure_installed = { 'prettier' },
    },
  },

  {
    -- see: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',
    dependencies = {
      'williamboman/mason.nvim',
    },
    event = 'VeryLazy',
    opts = {
      formatters = {
        --  TODO: add support for more filetypes that have community plugins?
        -- see: https://prettier.io/docs/en/plugins.html#community-plugins
        prettier = function()
          return {
            command = prettier_command ~= '' and prettier_command or prefer_bin_from_node_modules('prettier'),
            require_cwd = true, -- only activate if a config file is found
          }
        end,
      },
    },
  },

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
