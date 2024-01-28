-- see: https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/prettier.lua
-- see: https://www.lazyvim.org/extras/formatting/prettier

local mason_registry = require('mason-registry')

-- see: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-lazyvim/lua/plugins/lsp.lua
local function prefer_node_modules(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  local node_modules_path = vim.fn.getcwd() .. '/node_modules/.bin/' .. executable_name
  if vim.fn.executable(node_modules_path) == 1 then
    vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. node_modules_path, 'None' } }, false, {})
    return node_modules_path
  end

  local mason_path = mason_registry.get_package(executable_name):get_install_path()
    .. '/node_modules/.bin/'
    .. executable_name
  vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. mason_path, 'None' } }, false, {})
  return mason_path
end

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      table.insert(opts.ensure_installed, 'prettier')
    end,
  },

  {
    -- see: https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',
    event = 'VeryLazy',
    opts = {
      formatters = {
        --  TODO: add support for more filetypes that have community plugins?
        -- see: https://prettier.io/docs/en/plugins.html#community-plugins
        prettier = function()
          return {
            command = prefer_node_modules('prettier'),
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
