local M = {}

-- @type fun(): table
M.reset = function()
  return {}
end

-- @type fun(list:table, values:table): table
M.extend = function(list, values)
  vim.list_extend(list or {}, values)
end

return M
