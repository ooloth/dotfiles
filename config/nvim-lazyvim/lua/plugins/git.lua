return {
  { 'tpope/vim-fugitive', event = 'VeryLazy' },

  {
    'sindrets/diffview.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = function()
      local upstream_branch = 'origin/main'
      if vim.env.IS_WORK_LAPTOP == 'true' then
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
  },

  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        map('n', ']h', gs.next_hunk, 'Next hunk')
        map('n', '[h', gs.prev_hunk, 'Prev hunk')
        map('n', '<leader>gb', gs.blame_line, 'Blame line')
        map('n', '<leader>gtb', gs.toggle_current_line_blame, 'Line blame')
        map('n', '<leader>gtd', gs.toggle_deleted, 'Deleted lines')
        -- make hunks available as text objects
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<cr>', 'Select hunk')
      end,
    },
  },

  {
    'ruifm/gitlinker.nvim',
    event = 'VeryLazy',
    config = function()
      require('gitlinker').setup()
    end,
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>gy', desc = 'Copy URL for selected lines' },
    },
  },

  {
    'pwntester/octo.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {},
  },
}
