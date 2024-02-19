--  TODO: https://www.lazyvim.org/extras/formatting/prettier

-- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/prettier.lua
-- see: https://www.lazyvim.org/extras/formatting/prettier

local util = require('util')
local prefer_node_modules_executable = require('util.prefer_node_modules').prefer_node_modules_executable
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
            command = prefer_node_modules_executable('prettier'),
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
