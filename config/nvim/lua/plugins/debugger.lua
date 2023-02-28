return {
  -- {
  -- 'microsoft/vscode-js-debug',
  -- build = 'npm install --legacy-peer-deps && npm run compile',
  -- dependencies = { 'mfussenegger/nvim-dap' },
  -- },

  {
    'jay-babu/mason-nvim-dap.nvim',
    event = 'VeryLazy',
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    config = function(opts)
      require('mason-nvim-dap').setup(opts)
      require('mason-nvim-dap').setup_handlers({})
    end,
    opts = {
      automatic_installation = true,
      automatic_setup = true,
      ensure_installed = { 'js' },
    },
  },

  {
    'mxsdev/nvim-dap-vscode-js',
    event = 'VeryLazy',
    config = function()
      local dap = require('dap')
      local dap_js = require('dap-vscode-js')
      local mason_registry = require('mason-registry')
      local js_debug_pkg = mason_registry.get_package('js-debug-adapter')
      local js_debug_path = js_debug_pkg:get_install_path()
      dap_js.setup({
        debugger_path = js_debug_path,
        adapters = { 'pwa-node', 'node-terminal' }, -- which adapters to register in nvim-dap
      })
      for _, language in ipairs({ 'typescript', 'typescriptreact', 'javascript' }) do
        dap.configurations[language] = {
          { type = 'node-terminal', request = 'launch', command = 'npm run dev' },
          {
            name = 'Launch',
            type = 'pwa-node',
            request = 'launch',
            program = '${file}',
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            skipFiles = { '<node_internals>/**' },
            protocol = 'inspector',
            console = 'integratedTerminal',
          },
          -- {
          --   type = 'pwa-node',
          --   request = 'launch',
          --   name = 'Launch file (' .. language .. ')',
          --   program = '${file}',
          --   cwd = '${workspaceFolder}',
          -- },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach (' .. language .. ')',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
          },
        }
      end
    end,
  },

  { 'rcarriga/nvim-dap-ui', event = 'VeryLazy', dependencies = { 'mfussenegger/nvim-dap' } },
}
