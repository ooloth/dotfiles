-- TODO: testing: vitest
-- TODO: testing: jest
-- TODO: lsp: tsserver: prefer node modules version
-- TODO: lsp: eslint: prefer node modules version
-- TODO: dap

-- see: https://www.lazyvim.org/extras/lang/typescript

local extend = require('util').extend

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'eslint-lsp', 'js-debug-adapter', 'typescript-language-server' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      extend(opts.ensure_installed, { 'javascript', 'typescript', 'tsx' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        eslint = {
          -- Automatically fix fixable issues on save:
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#eslint
          on_attach = function(_, bufnr)
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = bufnr,
              command = 'EslintFixAll',
            })
          end,
          settings = {
            -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
            workingDirectory = { mode = 'auto' },
          },
        },
        tsserver = {
          -- see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#tsserver
          settings = {
            -- see: https://github.com/typescript-language-server/typescript-language-server/blob/master/docs/configuration.md#tsserver-options
            completions = {
              completeFunctionCalls = true,
            },
          },
        },
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        -- Also need to install @prettier/plugin-xml in project:
        -- https://github.com/prettier/plugin-xml
        javascript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
      },
    },
  },
}

-- {
-- 'microsoft/vscode-js-debug',
-- build = 'npm install --legacy-peer-deps && npm run compile',
-- dependencies = { 'mfussenegger/nvim-dap' },
-- },

-- {
--   'mxsdev/nvim-dap-vscode-js',
--   event = 'VeryLazy',
--   config = function()
--     local dap = require('dap')
--     local dap_js = require('dap-vscode-js')
--     local mason_registry = require('mason-registry')
--     local js_debug_pkg = mason_registry.get_package('js-debug-adapter')
--     local js_debug_path = js_debug_pkg:get_install_path()
--     dap_js.setup({
--       debugger_path = js_debug_path,
--       adapters = { 'pwa-node', 'node-terminal' }, -- which adapters to register in nvim-dap
--     })
--     for _, language in ipairs({ 'typescript', 'typescriptreact', 'javascript' }) do
--       dap.configurations[language] = {
--         { type = 'node-terminal', request = 'launch', command = 'npm run dev' },
--         {
--           name = 'Launch',
--           type = 'pwa-node',
--           request = 'launch',
--           program = '${file}',
--           rootPath = '${workspaceFolder}',
--           cwd = '${workspaceFolder}',
--           sourceMaps = true,
--           skipFiles = { '<node_internals>/**' },
--           protocol = 'inspector',
--           console = 'integratedTerminal',
--         },
--         -- {
--         --   type = 'pwa-node',
--         --   request = 'launch',
--         --   name = 'Launch file (' .. language .. ')',
--         --   program = '${file}',
--         --   cwd = '${workspaceFolder}',
--         -- },
--         {
--           type = 'pwa-node',
--           request = 'attach',
--           name = 'Attach (' .. language .. ')',
--           processId = require('dap.utils').pick_process,
--           cwd = '${workspaceFolder}',
--         },
--       }
--     end
--   end,
-- },
