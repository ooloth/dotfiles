local M = {}

-- @type fun(): table
M.reset = function()
  return {}
end

-- For extending a list-type table with another list-type table only (not a dictionary).
-- @type fun(list:table, values:table): table
M.extend = function(list, values)
  vim.list_extend(list or {}, values)
end

return M
