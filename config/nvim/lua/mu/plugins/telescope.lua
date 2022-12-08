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
    builtin = {
      find_files = {
        -- find_command = { 'fd', '--hidden', '--glob', '' },
        -- find_command = { 'rg', '--files', '--hidden', '-g', '!.git' },
        hidden = true, -- show hidden files
        no_ignore = true, -- show ignored files
      },
      git_files = {
        show_untracked = true,
      },
      oldfiles = {
        cwd_only = true,
      },
    },
    mappings = {
      i = {
        ['<C-k>'] = actions.move_selection_previous, -- move to prev result
        ['<C-j>'] = actions.move_selection_next, -- move to next result
      },
    },
  },
})

telescope.load_extension('fzf')
