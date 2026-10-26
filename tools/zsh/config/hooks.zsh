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

# Sets venv to the nearest virtual environment at or above the current directory, or to "". It runs
# on every shell start and every cd, so it walks up with ${dir:h} rather than starting a dirname
# subprocess for each level.
find_venv() {
  local dir="${PWD}"
  venv=""

  while [[ "${dir}" != "/" && -n "${dir}" ]]; do # don't go past the root directory
    if [[ -f "${dir}/.venv/bin/activate" ]]; then
      venv="${dir}/.venv"
      return
    elif [[ -f "${dir}/venv/bin/activate" ]]; then
      venv="${dir}/venv"
      return
    fi

    dir="${dir:h}" # move up one directory and try again
  done
}

activate_venv() {
  local venv=""
  find_venv

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
