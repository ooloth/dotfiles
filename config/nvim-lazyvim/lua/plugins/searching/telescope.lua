local actions = require('telescope.actions')
-- local undo_actions = require('telescope-undo.actions')
local Util = require('lazyvim.util')

-- Support opening multiple files in the same picker session:
-- see: https://github.com/nvim-telescope/telescope.nvim/issues/1048#issuecomment-1679797700
local select_one_or_multi = function(prompt_bufnr)
  local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()
  if not vim.tbl_isempty(multi) then
    require('telescope.actions').close(prompt_bufnr)
    for _, j in pairs(multi) do
      if j.path ~= nil then
        vim.cmd(string.format('%s %s', 'edit', j.path))
      end
    end
  else
    require('telescope.actions').select_default(prompt_bufnr)
  end
end

return {
  {
    'nvim-telescope/telescope.nvim',
    config = function(_, opts)
      local telescope = require('telescope')
      telescope.setup(opts)
      telescope.load_extension('fzf')
      telescope.load_extension('noice')
      telescope.load_extension('undo')
    end,
    dependencies = {
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'folke/noice.nvim',
      'debugloop/telescope-undo.nvim',
    },
    keys = function() -- replace all default keymaps
      return {
        -- { '<leader><space>', '<cmd>Telescope oldfiles cwd_only=true<cr>', desc = 'Recent files' },
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
        -- '<leader>fl' = 'Links in buffer' (see urlview.lua)
        { '<leader>fm', '<cmd>Telescope marks<cr>', desc = 'Mark' },
        { '<leader>fM', '<cmd>Telescope man_pages<cr>', desc = 'Man page' },
        { '<leader>fo', '<cmd>Telescope vim_options<cr>', desc = 'Option setting' },
        { '<leader>fr', '<cmd>Telescope oldfiles cwd_only=true<cr>', desc = 'Recent file' },
        { '<leader>fR', '<cmd>Telescope lsp_references<cr>', desc = 'References to symbol' },
        { '<leader>fs', Util.telescope('live_grep'), desc = 'String' },
        -- '<leader>ft' = 'Todo' (see todo-comment.lua)
        { '<leader>fw', Util.telescope('grep_string'), desc = 'Word under cursor' },
        { '<leader>fu', '<cmd>Telescope undo<cr>', desc = 'Undo history' },
        { '<leader>fz', '<cmd>Telescope resume<cr>', desc = 'Resume last search' },
        -- "git"
        { '<leader>gB', '<cmd>Telescope git_branches<cr>', desc = 'Branches' },
        { '<leader>gc', '<cmd>Telescope git_commits<cr>', desc = 'Commits' },
        { '<leader>gs', '<cmd>Telescope git_status<cr>', desc = 'Status' },
        { '<leader>gS', '<cmd>Telescope git_stash<cr>', desc = 'Stashes' },
        -- "help"
        { '<leader>h', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
        -- "keymaps"
        { '<leader>k', '<cmd>Telescope keymaps<cr>', desc = 'Keymaps' },
        -- "UI"
        { '<leader>uC', '<cmd>Telescope colorscheme enable_preview=true<cr>', desc = 'Colorschemes (with preview)' },
      }
    end,
    opts = {
      defaults = {
        layout_config = {
          flex = { width = 0.98, height = 0.97, preview_width = 0.5 },
          horizontal = { width = 0.98, height = 0.97, preview_width = 0.5 },
          -- prompt_position = 'top',
          vertical = { width = 0.98, height = 0.97, preview_width = 0.5 },
        },
        mappings = {
          i = {
            -- optionally select/deselect multiple files with <Tab>/<S-Tab>, then open all with <CR>
            ['<CR>'] = select_one_or_multi, -- still opens just one file if no multi-selection
            ['<esc>'] = actions.close,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
            ['<C-h>'] = actions.cycle_history_prev,
            ['<C-l>'] = actions.cycle_history_next,
          },
        },
        -- sorting_strategy = 'ascending',
      },
      pickers = {
        help_tags = {
          mappings = {
            i = {
              ['<CR>'] = 'select_vertical',
            },
            n = {
              ['<CR>'] = 'select_vertical',
            },
          },
        },
      },
      extensions = {
        undo = {
          use_delta = false,
          -- mappings = {
          --   i = {
          --     ['<C-cr>'] = undo_actions.restore,
          --     ['<cr>'] = undo_actions.yank_additions,
          --     ['<S-cr>'] = undo_actions.yank_deletions,
          --   },
          -- },
        },
      },
    },
  },
}
