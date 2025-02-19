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
  local CURRENT_DIRECTORY="$(basename ${PWD})"
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"
  local UV_VENV="${PWD}/.venv"
  local VENV=""

  if [ -f "${UV_VENV}/bin/activate" ]; then
    VENV="${UV_VENV}"
  elif [ -f "${PYENV_VENV}/bin/activate" ]; then
    VENV="${PYENV_VENV}"
  else
    # Deactivate any venv sticking from a previous directory and be done
    if [ -n "${VIRTUAL_ENV}" ] && command -v deactivate >/dev/null 2>&1; then
      deactivate
    fi
    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    # remove all pyenv paths from PATH (see: https://stackoverflow.com/a/62950499/8802485)
    export PATH=$(echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/')
    return 0
  fi

  # It's much faster to activate the new venv directly instead of using the pyenv shell integration
  # see: https://stackoverflow.com/a/74290100/8802485
  # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
  source "${VENV}/bin/activate"
}

# automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
update_python_env_vars
activate_venv
