------------------
-- LVIM OPTIONS --
------------------
-- TODO: remove redundant restatements of defaults? or is it nicer to make all my choices transparent?

lvim.format_on_save = true
lvim.lint_on_save = true
lvim.log.level = "warn"

-----------------
-- VIM OPTIONS --
-----------------

require("user.options")

------------------
-- AUTOCOMMANDS --
------------------
-- lvim.format_on_save = false
-- vim.api.nvim_create_autocmd("BufWritePre", {
--     pattern = "*",
--     callback = function()
--         if vim.bo.filetype == "typescript" or vim.bo.filetype == "javascript" or vim.bo.filetype == "javascriptreact" or
--             vim.bo.filetype == "typescriptreact"
--         then
--             -- NOTE: don't format javascript files
--             vim.cmd("EslintFixAll")
--             -- vim.lsp.buf.format({ name = "eslint" }) -- works too
--             return
--         else
--             require("lvim.lsp.utils").format { timeout_ms = 2000, filter = require("lvim.lsp.utils").format_filter }
--             -- vim.lsp.buf.format() -- careful, this overrides null-ls preferences
--             return
--         end
--     end,
-- })

-- FIXME: doesn't work
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   pattern = { '*.tsx', '*.ts', '*.jsx', '*.js' },
--   command = 'silent! EslintFixAll',
--   group = vim.api.nvim_create_augroup('MyAutocmdsESLint', {}),
-- })

-----------------
-- KEYMAPPINGS --
-----------------

require("user.keymaps").config() -- non-leader key mappings
require("user.which-key").config() -- leader key mappings

------------------
-- CORE PLUGINS --
------------------
-- After changing plugin config, exit and reopen LunarVim, Run :PackerInstall :PackerCompile

----------------
-- MY PLUGINS --
----------------


-- Change theme settings
lvim.colorscheme = "tokyonight"
-- vim.g.gruvbox_italic = 1
-- lvim.colorscheme = "gruvbox"

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
-- lvim.builtin.which_key.mappings["t"] = {
--   name = "+Trouble",
--   r = { "<cmd>Trouble lsp_references<cr>", "References" },
--   f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
--   d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
--   q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
--   l = { "<cmd>Trouble loclist<cr>", "LocationList" },
--   w = { "<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics" },
-- }

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "startify"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "css",
  "javascript",
  "json",
  "lua",
  "python",
  "tsx",
  "typescript",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

-- generic LSP settings

-- -- make sure server will always be installed even if the server is in skipped_servers list
lvim.lsp.installer.setup.ensure_installed = {
  "sumneko_lua",
  "jsonls",
}
-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }

---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" }, 1, 1)
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- * Skipped servers: [angularls,  cssmodules_ls,  emmet_ls, eslint,  graphql,  pylsp,  stylelint_lsp ]

-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "eslint"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- set a formatter, this will override the language server formatting capabilities (if it exists)
-- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "isort" },
  { command = "yapf" },
  { command = "prettier" },
  { command = "prismaFmt" },
}

-- set additional linters
-- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "eslint" },
  { command = "flake8" },
  { command = "markdownlint" },
  { command = "mypy" },
  { command = "proselint" },
  { command = "puglint" },
  { command = "shellcheck" },
  { command = "yamllint" },
}

-- Additional Plugins
lvim.plugins = {
  { 'gruvbox-community/gruvbox' },
  { 'tpope/vim-fugitive' },
  --     {
  --       "folke/trouble.nvim",
  --       cmd = "TroubleToggle",
  --     },
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
