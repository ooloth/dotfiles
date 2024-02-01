return {
  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-emoji' },
    opts = function(_, opts)
      local cmp = require('cmp')
      opts.mapping = cmp.mapping.preset.insert({
        ['<c-e>'] = cmp.mapping.abort(),
        ['<c-s>'] = cmp.mapping.complete(), -- show completion suggestions
        ['<cr>'] = cmp.mapping.confirm({ select = true }), -- accept currently selected item
        ['<c-j>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ['<c-k>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ['<c-u>'] = cmp.mapping.scroll_docs(-4), -- scroll preview window up
        ['<c-d>'] = cmp.mapping.scroll_docs(4), -- scroll preview window down
      })
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, { { name = 'emoji' } }))
      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }
    end,
  },
}
