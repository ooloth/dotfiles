-- TODO: https://github.com/stevearc/oil.nvim/blob/master/doc/recipes.md#toggle-file-detail-view
-- TODO: https://github.com/stevearc/oil.nvim/blob/master/doc/recipes.md#hide-gitignored-files

return {
  'stevearc/oil.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  keys = {
    { '<leader>ff', '<cmd>Oil<cr>', desc = 'Finder (oil)' },
  },
  opts = {
    -- see: https://github.com/stevearc/oil.nvim?tab=readme-ov-file#options
    delete_to_trash = true,
    -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
    -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
    -- Additionally, if it is a string that matches "actions.<name>",
    -- it will use the mapping at require("oil.actions").<name>
    -- Set to `false` to remove a keymap
    -- See :help oil-actions for a list of all available actions
    keymaps = {
      ['?'] = 'actions.show_help',
      ['<cr>'] = 'actions.select',
      ['-'] = 'actions.parent',
      -- ['_'] = 'actions.open_cwd',
      -- ['`'] = 'actions.cd',
      -- ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory' },
      ['<c-\\>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
      ['<c-->'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
      ['<c-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
      ['<c-p>'] = 'actions.preview',
      ['<esc>'] = 'actions.close',
      ['q'] = 'actions.close',
      ['<c-l>'] = 'actions.refresh',
      ['gs'] = 'actions.change_sort',
      ['gx'] = 'actions.open_external',
      ['g.'] = 'actions.toggle_hidden',
      ['g\\'] = 'actions.toggle_trash',
    },
    -- Set to false to disable all of the above keymaps
    use_default_keymaps = true,
    init = function()
      vim.keymap.set('n', '-', function()
        oil.open()

        -- Wait until oil has opened, for a maximum of 1 second.
        vim.wait(1000, function()
          return oil.get_cursor_entry() ~= nil
        end)
        if oil.get_cursor_entry() then
          oil.open_preview()
        end
      end)
    end,
  },
}
