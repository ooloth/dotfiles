local gitsigns_ok, gitsigns = pcall(require, 'gitsigns')
if not gitsigns_ok then
  return
end

local which_key_ok, wk = pcall(require, 'which-key')
if not which_key_ok then
  return
end

gitsigns.setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- set gitsigns navigation keymaps (non-leader key)
    map('n', ']c', function()
      if vim.wo.diff then
        return ']c'
      end
      vim.schedule(function()
        gs.next_hunk()
      end)
      return '<Ignore>'
    end, { expr = true })

    map('n', '[c', function()
      if vim.wo.diff then
        return '[c'
      end
      vim.schedule(function()
        gs.prev_hunk()
      end)
      return '<Ignore>'
    end, { expr = true })

    -- add "hunk" text object
    map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')

    -- set gitsigns action keymaps (leader key)
    wk.register({
      g = {
        b = {
          function()
            gs.blame_line({ full = true })
          end,
          'blame (full)',
        },
        h = {
          name = 'hunk',
          p = { gs.preview_hunk, 'preview' },
          r = { '<cmd>Gitsigns reset_hunk<cr>', 'reset' },
          s = { '<cmd>Gitsigns stage_hunk<cr>', 'stage' },
          u = { gs.undo_stage_hunk, 'unstage' },
        },
      },
    }, { buffer = bufnr, prefix = '<leader>' })
  end,
})
