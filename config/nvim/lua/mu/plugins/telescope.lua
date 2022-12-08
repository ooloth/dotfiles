local telescope_setup, telescope = pcall(require, 'telescope') -- import telescope plugin safely
if not telescope_setup then
  return
end

local actions_setup, actions = pcall(require, 'telescope.actions') -- import telescope actions safely
if not actions_setup then
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
