-- see: https://www.lazyvim.org/plugins/treesitter

return {
  'nvim-treesitter/nvim-treesitter',
  version = false, -- last release is way too old and doesn't work on Windows
  build = ':TSUpdate',
  event = { 'VeryLazy' },
  init = function(plugin)
    -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
    -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
    -- no longer trigger the **nvim-treesitter** module to be loaded in time.
    -- Luckily, the only things that those plugins need are the custom queries, which we make available
    -- during startup.
    require('lazy.core.loader').add_to_rtp(plugin)
    require('nvim-treesitter.query_predicates')
  end,
  cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
  keys = {
    { '<cr>', desc = 'Increment Selection' },
    { '<bs>', desc = 'Decrement Selection', mode = 'x' },
  },
  opts_extend = { 'ensure_installed' },
  opts = {
    -- install missing parsers when entering buffer
    auto_install = true,
    -- see: https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
    -- NOTE: must install parsers that ship with nvim to override them and avoid errors
    -- https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
    ensure_installed = {
      'bash', -- TODO: move to its own file
      'c', -- TODO: move to its own file
      'lua', -- TODO: move to its own file
      'markdown', -- TODO: move to its own file
      'markdown_inline', -- TODO: move to its own file
      'python', -- TODO: move to its own file
      'query', -- treesitter query language
      'regex',
      'tmux', -- TODO: move to its own file
      'vim', -- TODO: move to its own file
      'vimdoc', -- TODO: move to its own file
    },
    incremental_selection = {
      -- see: https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#incremental-selection
      keymaps = {
        init_selection = '<cr>',
        node_incremental = '<cr>',
        scope_incremental = false,
        node_decremental = '<bs>',
      },
    },
    textobjects = {
      move = {
        enable = true,
        goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
        goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
        goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
        goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
      },
    },
  },
  config = function(_, opts)
    require('nvim-treesitter.configs').setup(opts)
  end,
}
