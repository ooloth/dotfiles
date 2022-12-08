local setup, null_ls = pcall(require, 'null-ls') -- import null-ls plugin safely
if not setup then
  return
end

local formatting = null_ls.builtins.formatting -- to setup formatters
local diagnostics = null_ls.builtins.diagnostics -- to setup linters

-- to setup format on save
local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

-- configure null_ls
null_ls.setup({
  -- set up formatters & linters
  sources = {
    diagnostics.eslint_d, -- js/ts linter
    diagnostics.flake8, -- python linter
    diagnostics.mypy, -- python type-checker
    diagnostics.tsc, -- ts type-checker
    formatting.isort, -- python formatter
    formatting.prettierd, -- js/ts formatter
    formatting.stylua, -- lua formatter
  },
  -- configure format on save
  on_attach = function(current_client, bufnr)
    if current_client.supports_method('textDocument/formatting') then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            filter = function(client)
              -- use null-ls instead of lsp server for formatting
              return client.name == 'null-ls'
            end,
            bufnr = bufnr,
          })
        end,
      })
    end
  end,
})
