return {
  'neovim/nvim-lspconfig',
  dependencies = {
    {
      -- for library-specific json + yaml completions
      'b0o/SchemaStore.nvim',
      lazy = true,
      version = false, -- last release is way too old },
    },
  },
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
  -- TODO: return a function to disable all defaults?
  -- see: https://www.lazyvim.org/plugins/lsp#nvim-lspconfig
  opts = {
    -- options for vim.diagnostic.config()
    diagnostics = {
      float = { border = 'rounded', source = true },
    },
    -- LSP Server Settings
    servers = {
      -- suppress default LazyVim lua_ls installation
      -- see: https://github.com/LazyVim/LazyVim/issues/634#issuecomment-1515151425
      lua_ls = { enabled = false, mason = false },
      -- bashls = {},
      -- cssls = {},
      -- cssmodules_ls = {},
      -- dockerls = {},
      -- emmet_ls = {},
      -- html = {},
      -- marksman = {},
      -- -- TODO: only load if used by project
      -- tailwindcss = {},
    },
  },
}
