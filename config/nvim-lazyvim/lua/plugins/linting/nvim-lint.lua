return {
  {
    -- see: https://github.com/mfussenegger/nvim-lint
    'mfussenegger/nvim-lint',
    opts = {
      -- see: https://www.lazyvim.org/plugins/linting#nvim-lint
      -- see: https://github.com/mfussenegger/nvim-lint#available-linters
      linters_by_ft = {
        fish = {},
      },
    },
  },

  -- {
  --   'nvimtools/none-ls.nvim',
  --   opts = function() -- replace all default opts
  --     local nls = require('null-ls')
  --     return {
  --       sources = {
  --         nls.builtins.code_actions.proselint,
  --         nls.builtins.code_actions.shellcheck, -- bash linter
  --
  --         -- see: https://github.com/jose-elias-alvarez/typescript.nvim#setup-1
  --         require('typescript.extensions.null-ls.code-actions'),
  --
  --         nls.builtins.diagnostics.flake8, -- python linter
  --         nls.builtins.diagnostics.mypy, -- python type-checker
  --         nls.builtins.diagnostics.puglint, -- pug linter
  --         nls.builtins.diagnostics.shellcheck, -- bash linter
  --         nls.builtins.diagnostics.tsc, -- ts type-checker
  --         nls.builtins.diagnostics.zsh, -- zsh linter (basic compared to shellcheck for bash)
  --       },
  --     }
  --   end,
  -- },
}
