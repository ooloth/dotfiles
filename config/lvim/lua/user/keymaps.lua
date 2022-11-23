local M = {}

local keymap_options = { noremap = true, silent = true }

M.config = function()
  -- keymappings [view all the defaults by pressing <leader>Lk]

  -- LSP
  -- vim.keymap.set("n", "ga", "<cmd>Telescope lsp_code_actions<CR>", keymap_options)
  -- vim.keymap.set("n", "gh", "<Cmd>lua vim.lsp.buf.hover()<CR>", keymap_options)
  -- vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", keymap_options)
  -- vim.keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", keymap_options)

  -- Editing
  -- make Y behave like D and C by yanking remainder of line only
  -- vim.keymap.set("n", "Y", "y$", keymap_options)

  -- Navigate buffers
  vim.keymap.set("", "<Tab>", ":bnext<CR>", keymap_options)
  vim.keymap.set("", "<S-Tab>", ":bprevious<CR>", keymap_options)

  -- vim.keymap.set("", "<S-l>", ":bnext<CR>", keymap_options)
  -- vim.keymap.set("", "<S-h>", ":bprevious<CR>", keymap_options)

  -- exit help windows with Esc or q
  vim.cmd([[
    autocmd Filetype help nmap <buffer> <Esc> :q<CR>
    autocmd Filetype help nmap <buffer> q :q<CR>
  ]])

  ---------------
  -- TELESCOPE --
  ---------------
  -- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
  -- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
  local _, actions = pcall(require, "telescope.actions")
  lvim.builtin.telescope.defaults.mappings = {
    -- for input mode
    i = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
      ["<C-n>"] = actions.cycle_history_next,
      ["<C-p>"] = actions.cycle_history_prev,
    },
    -- for normal mode
    n = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
    },
  }
end

return M
