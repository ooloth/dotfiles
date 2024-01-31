return {
  'williamboman/mason.nvim',
  keys = function()
    -- remove all keymaps
    return {}
  end,
  opts = function()
    return {
      -- remove default installations
      ensure_installed = {},
    }
  end,
}
