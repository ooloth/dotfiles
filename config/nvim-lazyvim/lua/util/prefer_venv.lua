local M = {}

-- Check if a file or directory exists in this path
-- see: https://stackoverflow.com/a/40195356/8802485
M.path_exists = function(path)
  local ok, err, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

M.get_venv_executable_path = function(executable_name)
  if not vim.env.VIRTUAL_ENV then
    return ''
  end

  local executable_path = vim.env.VIRTUAL_ENV .. '/bin/' .. executable_name

  if M.path_exists(executable_path) then
    return executable_path
  end

  return ''
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
      return venv_executable_path
    end
  end

  -- otherwise, get the path to python outside a virtualenv from pyenv
  if executable_name == 'python' then
    -- return output of `pyenv which python` if it exists
    if vim.fn.executable('pyenv') == 1 then
      return string.gsub(vim.fn.system('pyenv which python'), '\n', '')
    end
    -- otherwise, return the output of `which python3` if it exists
    return vim.fn.exepath('python3')
  end

  -- otherwise, get the path to the Mason binary
  local mason_executable_path = M.get_mason_executable_path(executable_name)
  if mason_executable_path ~= '' then
    return mason_executable_path
  end

  -- fall back to the systemwide binary
  if M.path_exists('/usr/bin/' .. executable_name) then
    return '/usr/bin/' .. executable_name
  end

  if M.path_exists('/usr/local/bin/' .. executable_name) then
    return '/usr/local/bin/' .. executable_name
  end

  if M.path_exists('/usr/local/opt/' .. executable_name) then
    return '/usr/local/opt/' .. executable_name
  end

  return executable_name
end

return M
