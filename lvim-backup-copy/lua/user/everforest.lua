vim.opt.background = "dark"

-- See: https://github.com/sainnhe/everforest/blob/master/doc/everforest.txt
vim.g.everforest_background = "hard"
vim.g.everforest_diagnostic_line_highlight = 1
vim.g.everforest_diagnostic_text_highlight = 1
vim.g.everforest_diagnostic_virtual_text = "colored"
vim.g.everforest_enable_italic = 1
vim.g.everforest_disable_italic_comment = 0
vim.g.everforest_transparent_background = 1

vim.api.nvim_command("colorscheme everforest")
