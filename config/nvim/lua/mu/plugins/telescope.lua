local telescope_ok, telescope = pcall(require, 'telescope') -- import telescope plugin safely
if not telescope_ok then
  return
end

local actions_ok, actions = pcall(require, 'telescope.actions') -- import telescope actions safely
if not actions_ok then
  return
end

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ['<C-k>'] = actions.move_selection_previous, -- move to prev result
        ['<C-j>'] = actions.move_selection_next, -- move to next result
      },
    },
  },
})

telescope.load_extension('fzf')
