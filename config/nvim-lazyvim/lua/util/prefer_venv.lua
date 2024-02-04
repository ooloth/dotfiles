local M = {}

M.get_venv_executable_path = function(executable_name)
  return vim.env.VIRTUAL_ENV .. '/bin/' .. executable_name
end

M.get_mason_executable_path = function(executable_name)
  local mason_registry = require('mason-registry')
  return mason_registry.get_package(executable_name):get_install_path() .. '/venv/bin/' .. executable_name
end

M.is_installed_in_venv = function(executable_name)
  return M.get_venv_executable_path(executable_name) ~= ''
end

-- see: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-lazyvim/lua/plugins/lsp.lua
M.prefer_venv_executable = function(executable_name)
  -- get the path to the virtualenv binary (if it exists)
  if vim.env.VIRTUAL_ENV then
    local venv_executable_path = M.get_venv_executable_path(executable_name)
    if venv_executable_path ~= '' then
      -- vim.api.nvim_echo({ { 'Using path for ' .. executable_name .. ': ' .. venv_executable_path, 'None' } }, false, {})
      return venv_executable_path
    end
  end

  -- otherwise, get the path to the Mason binary
  return M.get_mason_executable_path(executable_name)
end

return M
