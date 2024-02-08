local M = {}

-- @type fun(): table
M.reset = function()
  return {}
end

-- see: https://github.com/rcarriga/nvim-notify?tab=readme-ov-file#usage
-- @type fun(): nil
M.inspect = function(value)
  vim.notify(vim.inspect(value), vim.log.levels.INFO)
end

-- For extending a list-type table with another list-type table only (not a dictionary).
-- @type fun(list:table, values:table): table
M.extend = function(list, values)
  vim.list_extend(list or {}, values)
end

return M
