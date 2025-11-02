function chpwd() {
  update_python_env_vars
  activate_venv
}

is_python_project() {
  # Any known folders or files in the current directory indicating this is a python project?
  if [ -d ".venv" ] || [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    return 0
  fi

  # Handle no glob matches on next line quietly (without an error message if no python files are found)
  setopt NULL_GLOB

  # Any python files in the current directory?
  for file in *.py; do
    if [ -e "${file}" ]; then
      return 0
    fi
  done

  return 1
}

update_python_env_vars() {
  if is_python_project; then
    export PYTHONPATH="${PWD}"
    export MYPYPATH="${PWD}"
  else
    export PYTHONPATH="${HOME}"
    export MYPYPATH="${HOME}"
  fi
}

activate_venv() {
  local current_directory="${PWD}"
  local venv=""

  # Function to find the nearest virtual environment
  find_venv() {
    local dir="$1" # start from the current directory

    while [ "${dir}" != "/" ]; do # don't go past the root directory
      local uv_venv_default="${dir}/.venv"
      local uv_venv_roadie="${dir}/venv"

      if [ -f "${uv_venv_default}/bin/activate" ]; then
        echo "${uv_venv_default}"
        return
      elif [ -f "${uv_venv_roadie}/bin/activate" ]; then
        echo "${uv_venv_roadie}"
        return
      fi

      dir="$(dirname "${dir}")" # move up one directory and try again
    done
  }

  venv=$(find_venv "${current_directory}")

  if [ -n "${venv}" ]; then
    source "${venv}/bin/activate"
  else
    # Deactivate any venv sticking from a previous directory and be done
    if have deactivate; then
      deactivate
    fi

    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
  fi
}

# Automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
update_python_env_vars
activate_venv
