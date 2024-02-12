return {
  'folke/persistence.nvim',
  init = function()
    require('persistence').load() -- automatically restore session on start
  end,
}
