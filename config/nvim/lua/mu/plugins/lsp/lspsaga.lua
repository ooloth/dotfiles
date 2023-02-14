local lspsaga_ok, lspsaga = pcall(require, 'lspsaga')
if not lspsaga_ok then
  return
end

-- float source currently only shows in lspsaga jump window
-- see: https://github.com/glepnir/lspsaga.nvim/issues/417#issuecomment-1210081841
vim.diagnostic.config({
  float = { source = true },
  severity_sort = true,
  update_in_insert = true,
  virtual_text = { prefix = ' ', source = false },
})

lspsaga.setup({
  ui = { border = 'rounded' },
  definition = { edit = '<cr>' },
  scroll_preview = { scroll_down = '<C-j>', scroll_up = '<C-k>' },
})
