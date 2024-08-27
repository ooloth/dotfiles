-- TODO: https://www.lazyvim.org/extras/editor/telescope
-- TODO: how to restrict searches to certain paths?
-- TODO: how to include/exclude certain file/folder patterns from a search?
-- TODO: use nvim-notify extension? does noice replace that?

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
      'folke/noice.nvim',
      'nvim-lua/plenary.nvim',
      'debugloop/telescope-undo.nvim',
      {
        -- see: https://github.com/danielfalk/smart-open.nvim?tab=readme-ov-file#installation
        'danielfalk/smart-open.nvim',
        branch = '0.2.x',
        dependencies = {
          'kkharji/sqlite.lua',
          'nvim-telescope/telescope-fzy-native.nvim',
        },
      },
      --    {
      --      'neovim/nvim-lspconfig',
      --      keys = function()
      --        -- see: https://www.lazyvim.org/extras/editor/telescope#nvim-lspconfig
      -- -- stylua: ignore
      -- return {
      --   { "gd", function() require("telescope.builtin").lsp_definitions({ reuse_win = true }) end, desc = "Goto Definition", has = "definition" },
      --   { "gr", "<cmd>Telescope lsp_references<cr>", desc = "References", nowait = true },
      --   { "gI", function() require("telescope.builtin").lsp_implementations({ reuse_win = true }) end, desc = "Goto Implementation" },
      --   { "gy", function() require("telescope.builtin").lsp_type_definitions({ reuse_win = true }) end, desc = "Goto T[y]pe Definition" },
      -- }
      --      end,
      --    },
    },
    keys = function()
      return {
        { '<leader>/', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Buffer' },
        { '<leader>,', '<cmd>Telescope command_history<cr>', desc = 'Recent commands' },

        { '<leader>gB', '<cmd>Telescope git_branches<cr>', desc = 'Branches' },
        { '<leader>gc', '<cmd>Telescope git_commits<cr>', desc = 'Commits' },
        { '<leader>gs', '<cmd>Telescope git_status<cr>', desc = 'Status' },
        { '<leader>gS', '<cmd>Telescope git_stash<cr>', desc = 'Stashes' },

        { '<leader>h', '<cmd>Telescope help_tags<cr>', desc = 'Help' },
        { '<leader>k', '<cmd>Telescope keymaps<cr>', desc = 'Keymaps' },

        { '<leader>s,', '<cmd>Telescope command_history<cr>', desc = 'Command (recent)' },
        { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = 'Auto command' },
        { '<leader>sc', '<cmd>Telescope commands<cr>', desc = 'Command (plugin)' },
        { '<leader>sd', '<cmd>Telescope diagnostics<cr>', desc = 'Diagnostics' },
        { '<leader>se', '<cmd>Telescope buffers cwd_only=true ignore_current_buffer=true<cr>', desc = 'Editor' },
        { '<leader>sf', '<cmd>Telescope smart_open cwd_only=true<cr>' },
        { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = 'Help page' },
        { '<leader>sj', '<cmd>Telescope jumplist<cr>', desc = 'Jump' },
        { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = 'Keymap' },
        -- '<leader>sl' = 'Links in buffer' (see urlview.lua)
        { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Mark' },
        { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = 'Man page' },
        { '<leader>sn', '<cmd>Telescope noice<cr>', desc = 'Notification (message)' },
        { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = 'Option (neovim setting)' },
        { '<leader>sr', '<cmd>Telescope lsp_references<cr>', desc = 'References to symbol' },
        { '<leader>ss', '<cmd>Telescope live_grep<cr>', desc = 'String' },
        -- '<leader>st' = 'Todo' (see todo-comment.lua)
        { '<leader>sw', '<cmd>Telescope grep_string<cr>', desc = 'Word under cursor' },
        { '<leader>su', '<cmd>Telescope undo<cr>', desc = 'Undo history' },
        { '<leader>sz', '<cmd>Telescope resume<cr>', desc = 'Resume last search' },

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
            -- see: https://github.com/debugloop/telescope-undo.nvim?tab=readme-ov-file#configuration
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

      -- Load extensions after setup
      require('telescope').load_extension('noice')
      require('telescope').load_extension('smart_open')
      require('telescope').load_extension('undo')
    end,
  },
}
