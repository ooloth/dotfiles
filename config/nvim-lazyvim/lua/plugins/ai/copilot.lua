return {
  'zbirenbaum/copilot.lua',
  event = 'BufRead',
  -- see: https://github.com/zbirenbaum/copilot.lua?tab=readme-ov-file#setup-and-configuration
  opts = {
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = false,
      },
    },
  },
  init = function()
    vim.keymap.set('i', '<Tab>', function()
      if require('copilot.suggestion').is_visible() then
        require('copilot.suggestion').accept()
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
      end
    end, { desc = 'Accept Copilot suggestion', silent = true })
  end,
}
