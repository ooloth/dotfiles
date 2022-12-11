local lspsaga_ok, lspsaga = pcall(require, 'lspsaga')
if not lspsaga_ok then
  return
end

-- float source currently only shows in lspsaga jump window
vim.diagnostic.config({ float = { source = true }, virtual_text = { source = true } })

lspsaga.init_lsp_saga({
  border_style = 'rounded',
  definition_action_keys = { edit = '<cr>' }, -- use enter to open file with definition preview
  finder_action_keys = { open = '<cr>' }, -- use enter to open file with finder
  move_in_saga = { prev = '<C-k>', next = '<C-j>' }, -- keybinds for navigation in lspsaga window
})
