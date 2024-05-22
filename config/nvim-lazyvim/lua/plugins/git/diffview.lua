return {
  'sindrets/diffview.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = function()
    local upstream_branch = 'origin/main'
    if vim.env.IS_WORK == 'true' then
      upstream_branch = 'origin/trunk'
    end

    return {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', 'Diff vs HEAD' },
      { '<leader>gD', '<cmd>DiffviewOpen ' .. upstream_branch .. '<cr>', 'Diff vs upstream' },
      { '<leader>gl', '<cmd>DiffviewFileHistory %<cr>', 'Log (file)' },
      { '<leader>gL', '<cmd>DiffviewFileHistory<cr>', 'Log (all)' },
    }
  end,
  -- see: https://github.com/sindrets/diffview.nvim#configuration
  -- opts = {
  -- opts = function(_, opts)
  --   local actions = require('diffview.actions')
  --   opts.keymaps = {
  --     view = {
  --       { 'n', '<j>', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
  --       { 'n', '<k>', actions.select_prev_entry, { desc = 'Open the diff for the previous file' } },
  --     },
  --     file_panel = {
  --       { 'n', '<c-u>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
  --       { 'n', '<c-d>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
  --     },
  --   }
  -- end,
  -- },
}
