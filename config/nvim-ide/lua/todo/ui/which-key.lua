-- TODO: move to relevant files?

return {
  'folke/which-key.nvim',
  opts = {
    -- see: https://www.lazyvim.org/plugins/editor#which-keynvim
    defaults = {
      ['g'] = { name = 'Go to' },
      ['gz'] = { name = 'Surround' },
      [']'] = { name = 'Next' },
      ['['] = { name = 'Previous' },
      ['<leader><tab>'] = { name = 'Tabs' },
      ['<leader>f'] = { name = 'File' },
      ['<leader>g'] = { name = 'Git', t = { name = 'Toggle' } },
      ['<leader>i'] = { name = 'Info' },
      ['<leader>o'] = { name = 'Open' },
      ['<leader>q'] = { name = 'Quit' },
      ['<leader>r'] = { name = 'Refactor' },
      ['<leader>u'] = { name = 'UI' },
      ['<leader>w'] = { name = 'Window' },
      ['<leader>x'] = { name = 'Diagnostics' },
    },
  },
  config = function(_, opts)
    local wk = require('which-key')
    wk.setup(opts)
    wk.register(opts.defaults)
  end,
}
