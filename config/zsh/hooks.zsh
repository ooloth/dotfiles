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
    if [ -e "$file" ]; then
      return 0
    fi
  done

  return 1
}

update_python_env_vars() {
  if is_python_project; then
    export PYTHONPATH="$PWD"
    export MYPYPATH="$PWD"
  else
    export PYTHONPATH="$HOME"
    export MYPYPATH="$HOME"
  fi
}

activate_venv() {
  if ! have uv && ! have pyenv; then
    return 0
  fi

  local CURRENT_DIRECTORY=$(basename $PWD)

  # assumes venv is named after the current directory
  local UV_VENV="${PWD}/.venv"
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

  if [ -d "$UV_VENV" ]; then
    local VENV="$UV_VENV"
  else
    local VENV="$PYENV_VENV"
  fi

  # Deactivate any venv sticking from a previous directory and be done
  if [[ ! -d "$VENV" ]]; then
    # remove all pyenv paths from PATH (see: https://stackoverflow.com/a/62950499/8802485)
    export PATH=$(echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/')
    deactivate
    unset VIRTUAL_ENV
    return 0
  fi

  # its much faster to activate the venv directly instead of using the pyenv shell integration
  # see: https://stackoverflow.com/a/74290100/8802485
  # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
  source "${VENV}/bin/activate"
}

# automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
update_python_env_vars
activate_venv
