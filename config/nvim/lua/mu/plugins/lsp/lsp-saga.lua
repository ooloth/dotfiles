local status, saga = pcall(require, "lspsaga") -- import lspsaga safely
if not status then
  return
end

saga.init_lsp_saga({
  definition_action_keys = { edit = "<CR>" }, -- use enter to open file with definition preview
  finder_action_keys = { open = "<CR>" }, -- use enter to open file with finder
  move_in_saga = { prev = "<C-k>", next = "<C-j>" }, -- keybinds for navigation in lspsaga window
})
