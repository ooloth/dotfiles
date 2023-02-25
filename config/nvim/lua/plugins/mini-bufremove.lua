return {
  {
    'echasnovski/mini.bufremove',
    keys = function() -- replace all keys
      return {
        {
          '<leader>bd',
          function()
            require('mini.bufremove').delete(0, false)
          end,
          desc = 'Delete buffer',
        },
        {
          '<leader>bD',
          function()
            require('mini.bufremove').delete(0, true)
          end,
          desc = 'Delete buffer (force)',
        },
        { '<leader>x', '<leader>bd', desc = 'Close buffer', remap = true },
        { '<leader>X', '<leader>bD', desc = 'Close buffer (force)', remap = true },
      }
    end,
  },
}
