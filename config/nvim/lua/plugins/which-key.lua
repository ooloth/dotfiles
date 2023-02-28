return {
  {
    'folke/which-key.nvim',
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      wk.register({
        mode = { 'n', 'v' },
        ['g'] = { name = 'Go to' },
        ['gz'] = { name = 'Surround' },
        [']'] = { name = 'Next' },
        ['['] = { name = 'Prev' },
        ['<leader>b'] = { name = 'Buffer' },
        ['<leader>d'] = { name = 'Debug' },
        ['<leader>f'] = { name = 'Find' },
        ['<leader>g'] = { name = 'Git' },
        ['<leader>gt'] = { name = 'Toggle' },
        ['<leader>o'] = { name = 'Open' },
        ['<leader>q'] = { name = 'Quit' },
        ['<leader>r'] = { name = 'Replace' },
        ['<leader>t'] = { name = 'Tab' },
        ['<leader>u'] = { name = 'UI' },
        ['<leader>w'] = { name = 'Window' },
        ['<leader>x'] = { name = 'Diagnostics' },
      })
    end,
  },
}
