-- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/prettier.lua
-- see: https://www.lazyvim.org/extras/formatting/prettier

-- cache the result of the first prefer_bin_from_node_modules call
local prettier_command = ''

local function prefer_bin_from_node_modules(executable_name)
  -- use the cached result if it exists
  if prettier_command ~= '' then
    return prettier_command
  end

  -- otherwise, get the path to the node_modules binary (if it exists)
  local node_modules_path = vim.fn.getcwd() .. '/node_modules/.bin/' .. executable_name
  if vim.fn.executable(node_modules_path) == 1 then
    prettier_command = node_modules_path
    return node_modules_path
  end

  -- otherwise, get the path to the Mason binary
  local mason_path = require('mason-registry').get_package(executable_name):get_install_path()
    .. '/node_modules/.bin/'
    .. executable_name
  prettier_command = mason_path
  return mason_path
end

local util = require('util')
local extend = util.extend
local reset = util.reset

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'prettier' })
    end,
  },

  {
    -- see: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',
    dependencies = {
      'williamboman/mason.nvim',
    },
    keys = reset(),
    opts = {
      -- see: https://github.com/stevearc/conform.nvim#options
      formatters = {
        --  TODO: add support for more filetypes that have community plugins?
        -- see: https://prettier.io/docs/en/plugins.html#community-plugins
        prettier = function()
          return {
            command = prefer_bin_from_node_modules('prettier'),
            require_cwd = true, -- only activate if a config file is found
          }
        end,
      },
      formatters_by_ft = {
        fish = {},
        -- use the "_" filetype to run formatters on filetypes that don't have other formatters configured.
        ['_'] = { 'trim_whitespace' },
      },
    },
  },
}
