return {
  'nvim-pack/nvim-spectre',
  keys = function() -- replace all keys
    return {
      {
        '<leader>rr',
        function()
          require('spectre').open()
        end,
        desc = 'Replace pattern',
      },
    }
  end,
}
