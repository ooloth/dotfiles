local close_buffer = function()
  require('mini.bufremove').delete(0, false)
end

local force_close_buffer = function()
  require('mini.bufremove').delete(0, true)
end

return {
  'echasnovski/mini.bufremove',
  keys = function()
    return {
      { '<leader>fc', close_buffer, desc = 'Close buffer' },
      { '<leader>fC', force_close_buffer, desc = 'Close buffer (force)' },
      { '<leader>c', close_buffer, desc = 'Close buffer' },
      { '<leader>C', force_close_buffer, desc = 'Close buffer (force)' },
    }
  end,
}
