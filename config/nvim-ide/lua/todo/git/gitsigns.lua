return {
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
}
