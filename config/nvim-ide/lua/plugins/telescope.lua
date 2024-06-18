-- TODO: https://www.lazyvim.org/extras/editor/telescope

-- Support opening multiple files in the same picker session:
-- see: https://github.com/nvim-telescope/telescope.nvim/issues/1048#issuecomment-2142669167
local select_one_or_multi = function(prompt_bufnr)
  local actions = require('telescope.actions')
  local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()

  if not vim.tbl_isempty(multi) then
    actions.close(prompt_bufnr)
    for _, j in pairs(multi) do
      if j.path ~= nil then
        if j.lnum ~= nil then
          vim.cmd(string.format('%s +%s %s', 'edit', j.lnum, j.path))
        else
          vim.cmd(string.format('%s %s', 'edit', j.path))
        end
      end
    end
  else
    actions.select_default(prompt_bufnr)
  end
end

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.6',
    dependencies = {
      {
        'folke/noice.nvim',
        config = function()
          require('telescope').load_extension('noice')
        end,
      },
      'nvim-lua/plenary.nvim',
      {
        -- see: https://github.com/danielfalk/smart-open.nvim?tab=readme-ov-file#installation
        'danielfalk/smart-open.nvim',
        branch = '0.2.x',
        config = function()
          require('telescope').load_extension('smart_open')
        end,
        dependencies = {
          'kkharji/sqlite.lua',
          {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
            config = function()
              -- see: https://github.com/nvim-telescope/telescope-fzy-native.nvim?tab=readme-ov-file#usage
              require('telescope').load_extension('fzf')
            end,
          },
          {
            'nvim-telescope/telescope-fzy-native.nvim',
            config = function()
              require('telescope').load_extension('fzy_native')
            end,
          },
        },
      },
      {
        'debugloop/telescope-undo.nvim',
        config = function()
          require('telescope').load_extension('undo')
        end,
      },
      {
        'folke/which-key.nvim',
        opts = {
          defaults = {
            ['<leader>s'] = { name = 'Search' },
          },
        },
      },
    },
    keys = function()
      return {
        { '<leader>/', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Buffer' },
        { '<leader>,', '<cmd>Telescope command_history<cr>', desc = 'Recent commands' },
        { '<leader>gB', '<cmd>Telescope git_branches<cr>', desc = 'Branches' },
        { '<leader>gc', '<cmd>Telescope git_commits<cr>', desc = 'Commits' },
        { '<leader>gs', '<cmd>Telescope git_status<cr>', desc = 'Status' },
        { '<leader>gS', '<cmd>Telescope git_stash<cr>', desc = 'Stashes' },
        -- "search"
        { '<leader>s,', '<cmd>Telescope command_history<cr>', desc = 'Command (recent)' },
        { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = 'Auto command' },
        { '<leader>sb', '<cmd>Telescope buffers cwd_only=true ignore_current_buffer=true<cr>', desc = 'Buffer' },
        { '<leader>sc', '<cmd>Telescope commands<cr>', desc = 'Command (plugin)' },
        { '<leader>sd', '<cmd>Telescope diagnostics<cr>', desc = 'Diagnostics' },
        { '<leader>sf', '<cmd>Telescope smart_open cwd_only=true<cr>' },
        { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = 'Help page' },
        { '<leader>h', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
        { '<leader>sj', '<cmd>Telescope jumplist<cr>', desc = 'Jump' },
        { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = 'Keymap' },
        { '<leader>k', '<cmd>Telescope keymaps<cr>', desc = 'Keymaps' },
        -- '<leader>sl' = 'Links in buffer' (see urlview.lua)
        { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Mark' },
        { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = 'Man page' },
        -- '<leader>sn', 'Noice' (see noice.lua)
        { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = 'Option setting' },
        { '<leader>sr', '<cmd>Telescope lsp_references<cr>', desc = 'References to symbol' },
        { '<leader>ss', '<cmd>Telescope live_grep<cr>', desc = 'String' },
        -- '<leader>st' = 'Todo' (see todo-comment.lua)
        { '<leader>sw', '<cmd>Telescope grep_string<cr>', desc = 'Word under cursor' },
        { '<leader>su', '<cmd>Telescope undo<cr>', desc = 'Undo history' },
        { '<leader>sz', '<cmd>Telescope resume<cr>', desc = 'Resume last search' },
        -- "UI"
        { '<leader>uC', '<cmd>Telescope colorscheme enable_preview=true<cr>', desc = 'Colorschemes (with preview)' },
      }
    end,
    config = function()
      local actions = require('telescope.actions')
      -- local undo_actions = require('telescope-undo.actions')

      require('telescope').setup({
        defaults = {
          layout_config = {
            flex = { width = 0.98, height = 0.97, preview_width = 0.5 },
            horizontal = { width = 0.98, height = 0.97, preview_width = 0.5 },
            prompt_position = 'top',
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
          sorting_strategy = 'ascending',
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
      })
    end,
  },
}
