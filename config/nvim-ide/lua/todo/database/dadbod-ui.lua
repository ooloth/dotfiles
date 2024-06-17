-- see: https://www.youtube.com/watch?v=NhTPVXP8n7w

local extend = require('util').extend

return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    {
      'nvim-treesitter/nvim-treesitter',
      opts = function(_, opts)
        extend(opts.ensure_installed, { 'sql' })
      end,
    },
    {
      'folke/which-key.nvim',
      opts = {
        defaults = {
          ['<leader>b'] = { name = 'Database' },
        },
      },
    },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    -- Your DBUI configuration
    -- https://github.com/kristijanhusak/vim-dadbod-ui
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_win_position = 'right' -- https://github.com/kristijanhusak/vim-dadbod-ui/issues/211#issuecomment-1828093490

    local set = vim.keymap.set
    set('n', '<leader>bu', '<cmd>DBUIToggle<CR>', { desc = 'Toggle DBUI' })
    set('n', '<leader>ba', '<cmd>DBUIAddConnection<CR>', { desc = 'Add DBUI connection' })
    set('n', '<leader>bf', '<cmd>DBUIFindBuffer<CR>', { desc = 'Find DBUI buffer' })
  end,
}
