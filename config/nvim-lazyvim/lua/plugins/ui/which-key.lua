-- TODO: move to relevant files?

return {
  {
    'folke/which-key.nvim',
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      wk.register({
        mode = { 'n', 'v' },
        ['g'] = { name = 'Go to' },
        [']'] = { name = 'Next' },
        ['['] = { name = 'Prev' },
        ['<leader>b'] = { name = 'Buffer' },
        ['<leader>d'] = { name = 'Debug' },
        ['<leader>f'] = { name = 'Find' },
        ['<leader>g'] = { name = 'Git' },
        ['<leader>gt'] = { name = 'Toggle' },
        ['<leader>i'] = { name = 'Info' },
        ['<leader>o'] = { name = 'Open' },
        ['<leader>q'] = { name = 'Quit' },
        ['<leader>r'] = { name = 'Replace' },
        ['<leader>u'] = { name = 'UI' },
        ['<leader>w'] = { name = 'Window' },
        ['<leader>x'] = { name = 'Diagnostics' },
        ['<leader>xt'] = { name = 'Toggle' },
      })
    end,
  },
}
