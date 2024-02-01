return {
  'neovim/nvim-lspconfig',
  init = function()
    local keys = require('lazyvim.plugins.lsp.keymaps').get()
    -- see: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
    keys[#keys + 1] = { 'R', '<cmd>LspRestart<cr>', desc = 'Restart LSP servers' }
    keys[#keys + 1] = { '<leader>if', '<cmd>ConformInfo<cr>', desc = 'Formatter info' }
    keys[#keys + 1] = { '<leader>il', '<cmd>LspInfo<cr>', desc = 'LSP info' }
    keys[#keys + 1] = { '<leader>m', '<cmd>Mason<cr>', desc = 'Mason' }
    keys[#keys + 1] = { '<leader>rs', vim.lsp.buf.rename, desc = 'Rename symbol', has = 'rename' }
    keys[#keys + 1] = { ']d', false }
    keys[#keys + 1] = { '[d', false }
    keys[#keys + 1] = { 'gd', false }
    keys[#keys + 1] = { 'gD', false }
    keys[#keys + 1] = { 'gt', false }
    keys[#keys + 1] = { 'K', false }
    keys[#keys + 1] = { '<leader>ca', mode = { 'n', 'v' }, false }
    keys[#keys + 1] = { '<leader>cA', false }
    keys[#keys + 1] = { '<leader>cd', false }
    keys[#keys + 1] = { '<leader>cf', false }
    keys[#keys + 1] = { '<leader>cf', mode = { 'v' }, false }
    keys[#keys + 1] = { '<leader>cl', false }
    keys[#keys + 1] = { '<leader>co', false }
    keys[#keys + 1] = { '<leader>cr', false }
  end,
  -- see: https://www.lazyvim.org/plugins/lsp#nvim-lspconfig
  opts = {
    -- options for vim.diagnostic.config()
    diagnostics = {
      float = { border = 'rounded', source = true },
    },
  },
}
