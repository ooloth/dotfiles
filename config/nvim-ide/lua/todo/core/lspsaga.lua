local extend = require('util').extend

return {
  'nvimdev/lspsaga.nvim',
  event = 'BufRead',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' },
    {
      'nvim-treesitter/nvim-treesitter',
      opts = function(_, opts)
        extend(opts.ensure_installed, { 'markdown', 'markdown_inline' })
      end,
    },
  },
  keys = function()
    -- stylua: ignore
    return {
      { ']d', '<cmd>Lspsaga diagnostic_jump_next<cr>', desc = 'Next diagnostic' },
      { '[d', '<cmd>Lspsaga diagnostic_jump_prev<cr>', desc = 'Previous diagnostic' },
      { ']e', function() require('lspsaga.diagnostic'):goto_next({ severity = vim.diagnostic.severity.ERROR }) end, desc = 'Next diagnostic' },
      { '[e', function() require('lspsaga.diagnostic'):goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, desc = 'Previous diagnostic' },
      { 'ga', '<cmd>Lspsaga code_action<cr>', desc = 'Code actions' },
      { 'gd', '<cmd>Lspsaga goto_definition<cr>', desc = 'Definition' },
      { 'gh', '<cmd>Lspsaga hover_doc<cr>', desc = 'Hover' },
      { 'go', '<cmd>Lspsaga outline<cr>', desc = 'Symbol outline' },
      { 'gt', '<cmd>Lspsaga goto_type_definition<cr>', desc = 'Type definition' },
      { '<leader>xn', ']x', desc = 'Next diagnostic', remap = true },
      { '<leader>xp', '[x', desc = 'Previous diagnostic', remap = true },
    }
  end,
  opts = {
    code_action = {
      quit = { 'q', '<esc>' },
      keys = { exec = '<CR>' },
    },
    diagnostic = {
      extend_relatedInformation = true,
      keys = { quit = '<esc>' },
      max_width = 0.99,
    },
    finder = {
      -- see: https://nvimdev.github.io/lspsaga/finder/
      default = 'def+ref+imp',
      keys = {
        jump_to = 'p',
        edit = { 'o', '<CR>' },
        vsplit = 'v',
        tabe = 't',
      },
      left_width = 0.5,
      max_height = 0.8,
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
        quit = { 'q', '<esc>' },
      },
    },
    rename = {
      -- see: https://nvimdev.github.io/lspsaga/rename/
      in_select = false,
      keys = {
        quit = { '<Esc>' },
        exec = '<CR>',
      },
    },
    scroll_preview = { scroll_down = '<C-d>', scroll_up = '<C-u>' },
    symbol_in_winbar = { enable = false },
    ui = { border = 'rounded' },
  },
}
