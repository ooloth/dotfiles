-- sticky scroll context
return {
  'nvim-treesitter/nvim-treesitter-context',
  after = 'nvim-treesitter',
  opts = {
    -- see: https://github.com/nvim-treesitter/nvim-treesitter-context?tab=readme-ov-file#configuration
  },
  -- init = function()
  --   vim.api.nvim_set_hl(0, 'TreesitterContext', { bg = '#1e1e2e', underline = false })
  -- end,
}
