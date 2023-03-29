-- see: https://harrisoncramer.me/debugging-in-neovim/

local mason_nvim_dap = require('plugins.dap.mason-nvim-dap')
-- local dap = require('plugins.dap.dap')
-- local javascript = require('plugins.dap.javascript')
-- local python = require('plugins.dap.python')
-- local dap_ui = require('plugins.dap.dap-ui')

return {
  -- 1. automatically install necessary debuggers (not vim-related)
  mason_nvim_dap,
  -- dap,
  -- javascript,
  -- python,
  -- dap_ui,
}
