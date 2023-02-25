local actions = require('telescope.actions')
local Util = require('lazyvim.util')

return {
  {
    'nvim-telescope/telescope.nvim',
    config = function(_, opts)
      local telescope = require('telescope')
      telescope.setup(opts)
      telescope.load_extension('fzf')
    end,
    dependencies = {
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    keys = function() -- replace all default keymaps
      return {
        {
          '<leader><space>',
          '<cmd>Telescope buffers cwd_only=true ignore_current_buffer=true<cr>',
          desc = 'Buffers',
        },
        { '<leader>/', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Search buffer' },
        { '<leader>,', '<cmd>Telescope command_history<cr>', desc = 'Recent commands' },
        -- "find"
        { '<leader>f,', '<cmd>Telescope command_history<cr>', desc = 'Command (recent)' },
        { '<leader>fa', '<cmd>Telescope autocommands<cr>', desc = 'Auto command' },
        { '<leader>fb', '<cmd>Telescope buffers cwd_only=true ignore_current_buffer=true<cr>', desc = 'Buffer' },
        { '<leader>fc', '<cmd>Telescope commands<cr>', desc = 'Command (plugin)' },
        { '<leader>fd', '<cmd>Telescope diagnostics<cr>', desc = 'Diagnostics' },
        { '<leader>ff', Util.telescope('files'), desc = 'File' },
        { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = 'Help page' },
        { '<leader>fj', '<cmd>Telescope jumplist<cr>', desc = 'Jump' },
        { '<leader>fk', '<cmd>Telescope keymaps<cr>', desc = 'Keymap' },
        { '<leader>fm', '<cmd>Telescope marks<cr>', desc = 'Mark' },
        { '<leader>fM', '<cmd>Telescope man_pages<cr>', desc = 'Man page' },
        -- '<leader>fn' = 'Notifications' (see noice.lua)
        { '<leader>fo', '<cmd>Telescope vim_options<cr>', desc = 'Option setting' },
        { '<leader>fr', '<cmd>Telescope oldfiles cwd_only=true<cr>', desc = 'Recent file' },
        { '<leader>fR', '<cmd>Telescope lsp_references<cr>', desc = 'References to symbol' },
        { '<leader>fs', Util.telescope('live_grep'), desc = 'String' },
        -- '<leader>ft' = 'Todo' (see todo-comment.lua)
        { '<leader>fw', Util.telescope('grep_string'), desc = 'Word under cursor' },
        { '<leader>fz', '<cmd>Telescope resume<cr>', desc = 'Resume last search' },
        -- "git"
        { '<leader>gB', '<cmd>Telescope git_branches<cr>', desc = 'Branches' },
        { '<leader>gc', '<cmd>Telescope git_commits<cr>', desc = 'Commits' },
        { '<leader>gs', '<cmd>Telescope git_status<cr>', desc = 'Status' },
        { '<leader>gS', '<cmd>Telescope git_stash<cr>', desc = 'Stashes' },
        -- "help"
        { '<leader>h', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
        -- "jumps"
        { '<leader>j', '<cmd>Telescope jumplist<cr>', desc = 'Jumps' },
        -- "keymaps"
        { '<leader>k', '<cmd>Telescope keymaps<cr>', desc = 'Keymaps' },
        -- "ui"
        { '<leader>uC', '<cmd>Telescope colorscheme enable_preview=true<cr>', desc = 'Colorscheme with preview' },
      }
    end,
    opts = {
      defaults = {
        layout_config = {
          flex = { width = 0.99, height = 0.99, preview_width = 0.55 },
          horizontal = { width = 0.99, height = 0.99, preview_width = 0.55 },
          vertical = { width = 0.99, height = 0.99, preview_width = 0.55 },
        },
        mappings = {
          i = {
            ['<esc>'] = actions.close,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
            ['<C-h>'] = actions.cycle_history_prev,
            ['<C-l>'] = actions.cycle_history_next,
          },
        },
      },
    },
  },
}
