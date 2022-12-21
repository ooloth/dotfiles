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

  textobjects = {
    -- see: https://github.com/nvim-treesitter/nvim-treesitter-textobjects#text-objects-move
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },

    -- see: https://github.com/nvim-treesitter/nvim-treesitter-textobjects#text-objects-select
    select = {
      enable = true,
      include_surrounding_whitespace = true,
      keymaps = {
        -- see: https://github.com/nvim-treesitter/nvim-treesitter-textobjects#built-in-textobjects
        ['ac'] = { query = '@class.outer', desc = 'outer class' },
        ['ic'] = { query = '@class.inner', desc = 'inner class' },
        ['af'] = { query = '@function.outer', desc = 'outer function' },
        ['if'] = { query = '@function.inner', desc = 'inner function' },
      },

      lookahead = true, -- automatically jump forward to textobj, similar to targets.vim
    },
  },
})

-- NOTE: caused annoying issue of either autofolding or autounfolding (both unwanted)
-- fold using treesitter
-- see: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Installation#packernvim
-- see: https://github.com/nvim-treesitter/nvim-treesitter#folding
-- vim.api.nvim_create_autocmd({ 'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile', 'BufWinEnter' }, {
--   group = vim.api.nvim_create_augroup('TS_FOLD_WORKAROUND', {}),
--   callback = function()
--     vim.opt.foldmethod = 'expr'
--     vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
--   end,
-- })
