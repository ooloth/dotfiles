return {
  {
    'echasnovski/mini.bufremove',
    -- stylua: ignore
    keys = function() 
      return {
        { '<leader>bc', function() require('mini.bufremove').delete(0, false) end, desc = 'Close buffer' },
        { '<leader>bC', function() require('mini.bufremove').delete(0, true) end, desc = 'Close buffer (force)' },
        { '<leader>c', '<leader>bc', desc = 'Close buffer', remap = true },
        { '<leader>C', '<leader>bC', desc = 'Close buffer (force)', remap = true },
      }
    end,
  },
}
