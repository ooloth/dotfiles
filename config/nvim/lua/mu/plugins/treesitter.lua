local treesitter_ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if not treesitter_ok then
  return
end

-- configure treesitter
treesitter.setup({
  -- install missing parsers when entering buffer
  auto_install = true,

  -- enable autotagging (w/ nvim-ts-autotag plugin)
  autotag = { enable = true },

  -- ensure these language parsers are installed
  ensure_installed = {
    'bash',
    'comment',
    'css',
    'diff',
    'dockerfile',
    'gitcommit',
    -- 'gitignore', -- currently errors
    'graphql',
    'help',
    'html',
    'javascript',
    'jsdoc',
    'json',
    'json5',
    'jsonc',
    'lua',
    'markdown',
    'php',
    'pug',
    'python',
    'svelte',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vue',
    'yaml',
  },

  -- highlight syntax with treesitter
  highlight = { enable = true },

  -- select incrementally using treesitter
  -- see: https://github.com/nvim-treesitter/nvim-treesitter#incremental-selection
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },

  -- make = operator use treesitter
  -- see: https://github.com/nvim-treesitter/nvim-treesitter#indentation
  indent = { enable = true },
})

-- fold using treesitter
-- see: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Installation#packernvim
-- see: https://github.com/nvim-treesitter/nvim-treesitter#folding
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile', 'BufWinEnter' }, {
  group = vim.api.nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
  callback = function()
    vim.opt.foldmethod = 'expr'
    vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
  end,
})
