return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    keys = function() -- replace all default keys
      return {
        {
          '<leader>fe',
          function()
            -- see: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/editor.lua
            require('neo-tree.command').execute({ toggle = true, dir = vim.loop.cwd() })
          end,
          desc = 'Explorer',
        },
        { '<leader>e', '<leader>fe', desc = 'Explorer', remap = true },
      }
    end,
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
  },
}
