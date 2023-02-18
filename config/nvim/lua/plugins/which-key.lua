local Util = require('lazyvim.util')

return {
  {
    'folke/which-key.nvim',
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      local keymaps = {
        mode = { 'n', 'v' },
        ['g'] = { name = 'Go to' },
        ['gz'] = { name = 'Surround' },
        [']'] = { name = 'Next' },
        ['['] = { name = 'Prev' },
        ['<leader><tab>'] = { name = 'Tab' },
        ['<leader>b'] = { name = 'Buffer' },
        ['<leader>c'] = { name = 'Code' },
        ['<leader>f'] = { name = 'Find' },
        ['<leader>g'] = { name = 'Git' },
        ['<leader>gt'] = { name = 'Toggle' },
        ['<leader>o'] = { name = 'Open' },
        ['<leader>q'] = { name = 'Quit/Session' },
        ['<leader>s'] = { name = 'Search' },
        ['<leader>u'] = { name = 'UI' },
        ['<leader>w'] = { name = 'Window' },
        ['<leader>x'] = { name = 'Diagnostics' },
      }
      if Util.has('noice.nvim') then
        keymaps['<leader>n'] = { name = 'Notifications' }
      end
      wk.register(keymaps)
    end,
  },
}
