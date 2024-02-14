return {
  'nvim-treesitter/nvim-treesitter',
  -- see: https://github.com/nvim-neotest/neotest/issues/303#issuecomment-1783017888
  lazy = false,
  opts = {
    -- install missing parsers when entering buffer
    auto_install = true,
    -- see: https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
    ensure_installed = {
      'comment',
      'css',
      'diff',
      'gitcommit',
      'html',
      'jsdoc',
      'json',
      'jsonc',
      'json5',
      'regex',
      'vim',
    },
    incremental_selection = {
      keymaps = {
        init_selection = '<cr>',
        node_incremental = '<cr>',
        scope_incremental = '<nop>',
        node_decremental = '<bs>',
      },
    },
  },
}
