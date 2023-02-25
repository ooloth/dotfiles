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
        ['<leader>d'] = { name = 'Diagnostics' },
        ['<leader>f'] = { name = 'Find' },
        ['<leader>g'] = { name = 'Git' },
        ['<leader>gt'] = { name = 'Toggle' },
        ['<leader>i'] = { name = 'Inspect' },
        ['<leader>o'] = { name = 'Open' },
        ['<leader>q'] = { name = 'Quit/Session' },
        ['<leader>s'] = { name = 'Search' },
        ['<leader>u'] = { name = 'UI' },
        ['<leader>w'] = { name = 'Window' },
      }
      wk.register(keymaps)
    end,
  },
}
