local M = {}

local keymap_options = { noremap = true, silent = true }

M.setup = function()
  -- LSP
	vim.api.nvim_set_keymap('n', "ga", "<cmd>Telescope lsp_code_actions<cr>", keymap_options)
	vim.api.nvim_set_keymap('n', "gh", "<Cmd>lua vim.lsp.buf.hover()<CR>", keymap_options)
	vim.api.nvim_set_keymap('n', "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", keymap_options)
	vim.api.nvim_set_keymap('n', "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", keymap_options)

  -- Editing
	-- make Y behave like D and C by yanking remainder of line only
  vim.api.nvim_set_keymap('n', "Y", "y$", keymap_options)

  -- Navigate buffers
  vim.api.nvim_set_keymap('', '<Tab>', ':bnext<CR>', keymap_options)
  vim.api.nvim_set_keymap('', '<S-Tab>', ':bprevious<CR>', keymap_options)

  -- exit help windows with Esc or q
  vim.cmd([[
    autocmd Filetype help nmap <buffer> <Esc> :q<CR>
    autocmd Filetype help nmap <buffer> q :q<CR>
  ]])

  -- Colemak DH

  -- m -> h
  vim.api.nvim_set_keymap('', 'm', 'h', keymap_options)
  vim.api.nvim_set_keymap('', 'M', 'H', keymap_options)

  -- n -> j
  vim.api.nvim_set_keymap('', 'n', 'j', keymap_options)
  vim.api.nvim_set_keymap('', 'N', 'J', keymap_options)

  -- e -> k
  vim.api.nvim_set_keymap('', 'e', 'k', keymap_options)
  vim.api.nvim_set_keymap('', 'E', 'K', keymap_options)

  -- i -> l
  vim.api.nvim_set_keymap('', 'i', 'l', keymap_options)
  vim.api.nvim_set_keymap('', 'I', 'L', keymap_options)

  -- h -> i
  vim.api.nvim_set_keymap('', 'h', 'i', keymap_options)
  vim.api.nvim_set_keymap('', 'H', 'I', keymap_options)

  -- j -> n
  vim.api.nvim_set_keymap('', 'j', 'n', keymap_options)
  vim.api.nvim_set_keymap('', 'J', 'N', keymap_options)

  -- k -> m
  vim.api.nvim_set_keymap('', 'k', 'm', keymap_options)
  vim.api.nvim_set_keymap('', 'K', 'M', keymap_options)

  -- l -> e
  vim.api.nvim_set_keymap('', 'l', 'e', keymap_options)
  vim.api.nvim_set_keymap('', 'L', 'E', keymap_options)
end

return M
