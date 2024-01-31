return {
  'nvim-treesitter/nvim-treesitter',
  opts = {
    -- install missing parsers when entering buffer
    auto_install = true,
    ensure_installed = {
      'bash',
      'comment',
      'css',
      'diff',
      'gitcommit',
      'html',
      'javascript',
      'jsdoc',
      'json',
      'jsonc',
      'json5',
      'lua',
      'luap',
      'markdown',
      'markdown_inline',
      'python',
      'regex',
      'tsx',
      'typescript',
      'vim',
      'yaml',
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
