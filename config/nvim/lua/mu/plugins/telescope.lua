local telescope_ok, telescope = pcall(require, 'telescope') -- import telescope plugin safely
if not telescope_ok then
  return
end

local actions_ok, actions = pcall(require, 'telescope.actions') -- import telescope actions safely
if not actions_ok then
  return
end

local trouble_ok, trouble = pcall(require, 'trouble.providers.telescope')
if not trouble_ok then
  return
end

telescope.setup({
  defaults = {
    builtin = {
      find_files = {
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
        ['<c-j>'] = actions.move_selection_next, -- move to next result
        ['<c-k>'] = actions.move_selection_previous, -- move to prev result
        ['<c-t>'] = trouble.open_with_trouble, -- send list to trouble
      },
      n = {
        ['<c-t>'] = trouble.open_with_trouble, -- send list to trouble
      },
    },
  },
})

telescope.load_extension('fzf')
