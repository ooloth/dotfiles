local M = {}

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

M.get_system_executable_path = function(executable_name)
  if vim.fn.executable('/usr/bin/' .. executable_name) == 1 then
    return executable_name
  end

  if vim.fn.executable('/usr/local/bin/' .. executable_name) == 1 then
    return '/usr/local/bin/' .. executable_name
  end

  if vim.fn.executable('/usr/local/opt/' .. executable_name) == 1 then
    return '/usr/local/opt/' .. executable_name
  end

  return ''
end

return M
