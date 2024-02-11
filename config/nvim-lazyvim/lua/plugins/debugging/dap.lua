-- see: https://www.lazyvim.org/extras/dap/core#nvim-dap
local prefer_venv_executable = require('util.prefer_venv').prefer_venv_executable

local continue_debugging = function()
  -- (re-)reads launch.json if present
  if vim.fn.filereadable('.vscode/launch.json') then
    require('dap.ext.vscode').load_launchjs(nil, {
      ['pwa-node'] = { 'typescript', 'javascript' },
    })

    -- override console in all configurations
    local dap_configurations = require('dap').configurations

    for _, config in ipairs(dap_configurations) do
      config.console = 'integratedTerminal'
      config.justMyCode = true
    end

    -- override pythonPath in all python configurations
    local python_configurations = dap_configurations.python or {}
    local python = prefer_venv_executable('python')

    for _, config in ipairs(python_configurations) do
      config.pythonPath = python
    end
  end

  require('dap').continue()
end

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    {
      'rcarriga/nvim-dap-ui',
      opts = {
        controls = {
          element = 'repl',
          enabled = false,
        },
        element_mappings = {
          scopes = {},
          watches = {},
          stacks = {},
          breakpoints = {},
          console = {},
          repl = {},
        },
        expand_lines = true,
        floating = {
          border = 'single',
          mappings = {
            close = { 'q', '<Esc>' },
          },
        },
        icons = { collapsed = '', current_frame = '', expanded = '' },
        layouts = {
          {
            elements = {
              { id = 'scopes', size = 0.45 },
              { id = 'watches', size = 0.15 },
              { id = 'breakpoints', size = 0.15 },
              { id = 'stacks', size = 0.25 },
            },
            position = 'right',
            size = 75,
          },
          {
            elements = {
              { id = 'repl', size = 0.5 },
              { id = 'console', size = 0.5 },
            },
            position = 'bottom',
            size = 15,
          },
        },
        mappings = {
          edit = 'e',
          expand = { 'l', '<CR>', '<2-LeftMouse>' },
          open = 'o',
          remove = 'd',
          repl = 'r',
          toggle = 't',
        },
        render = {
          indent = 1,
          max_value_lines = 1000,
        },
      },
      config = function(_, opts)
        local dap = require('dap')
        local dapui = require('dapui')
        dapui.setup(opts)
        dap.listeners.after.event_initialized['dapui_config'] = function()
          dapui.open({})
        end
        dap.listeners.before.event_terminated['dapui_config'] = function()
          dapui.close({})
        end
        dap.listeners.before.event_exited['dapui_config'] = function()
          dapui.close({})
        end
      end,
    },

    -- virtual text for the debugger
    {
      'theHamsta/nvim-dap-virtual-text',
      opts = {},
    },

    -- which key integration
    {
      'folke/which-key.nvim',
      opts = {
        defaults = {
          ['<leader>d'] = { name = '+Debug' },
        },
      },
    },

    {
      'jay-babu/mason-nvim-dap.nvim',
      dependencies = 'mason.nvim',
      cmd = { 'DapInstall', 'DapUninstall' },
      opts = {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
        },
      },
    },
  },

  -- stylua: ignore
  keys = {
    -- { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>dc", continue_debugging, desc = "Continue" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dd", continue_debugging, desc = "Start debugger" },
    { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Move down stack" },
    { "<leader>dk", function() require("dap").up() end, desc = "Move up stack" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").restart() end, desc = "Restart" },
    { "<leader>ds", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dx", function() require("dap").terminate() end, desc = "End session" },
    { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
    { "<leader>dw", function() require("dapui").elements.watches.add() end, desc = "Watch symbol under cursor" },
  },

  config = function()
    local Config = require('lazyvim.config')
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })

    for name, sign in pairs(Config.icons.dap) do
      sign = type(sign) == 'table' and sign or { sign }
      vim.fn.sign_define(
        'Dap' .. name,
        { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] }
      )
    end
  end,
}
