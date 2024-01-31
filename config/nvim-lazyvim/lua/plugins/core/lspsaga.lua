return {
  'glepnir/lspsaga.nvim',
  event = 'BufRead',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' },
    { 'nvim-treesitter/nvim-treesitter' }, -- please make sure you install markdown and markdown_inline parsers
  },
  keys = function()
    return {
      { ']x', '<cmd>Lspsaga diagnostic_jump_next<cr>', desc = 'Next diagnostic' },
      { '[x', '<cmd>Lspsaga diagnostic_jump_prev<cr>', desc = 'Previous diagnostic' },
      { 'ga', '<cmd>Lspsaga code_action<cr>', desc = 'Code actions' },
      { 'gd', '<cmd>Lspsaga lsp_finder<cr>', desc = 'Definition, references & implentations' },
      { 'gD', '<cmd>Lspsaga goto_definition<cr>', desc = 'Go to definition' },
      { 'gh', '<cmd>Lspsaga hover_doc<cr>', desc = 'Hover' },
      { 'go', '<cmd>Lspsaga outline<cr>', desc = 'Outline' },
      { 'gt', '<cmd>Lspsaga goto_type_definition<cr>', desc = 'Go to type definition' },
      {
        '<leader>a',
        'ga',
        desc = 'Actions',
        remap = true,
      },
      {
        '<leader>xn',
        ']x',
        desc = 'Next diagnostic',
        remap = true,
      },
      {
        '<leader>xp',
        '[x',
        desc = 'Previous diagnostic',
        remap = true,
      },
    }
  end,
  opts = {
    code_action = {
      quit = { 'q', '<esc>' },
      keys = {
        exec = '<CR>',
      },
    },
    diagnostic = {
      max_width = 0.99,
      keys = { quit = '<esc>' },
    },
    finder = {
      max_height = 0.99,
      keys = {
        jump_to = 'p',
        edit = { 'o', '<CR>' },
        vsplit = 'v',
        tabe = 't',
      },
    },
    hover = { max_width = 0.99 },
    lightbulb = { enable = false },
    outline = {
      win_position = 'right',
      win_with = '',
      win_width = 50,
      show_detail = true,
      auto_preview = true,
      auto_refresh = true,
      auto_close = true,
      custom_sort = nil,
      keys = {
        jump = 'o',
        expand_collapse = 'u',
        quit = '<esc>',
      },
    },
    rename = {
      quit = '<C-c>',
      in_select = false,
    },
    scroll_preview = { scroll_down = '<C-d>', scroll_up = '<C-u>' },
    symbol_in_winbar = { enable = false },
    ui = { border = 'rounded' },
  },
}
