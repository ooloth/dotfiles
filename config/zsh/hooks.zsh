function chpwd() {
  update_python_env_vars
  activate_pyenv_venv
}

is_python_project() {
  if [ -d ".venv" ] || [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || ls *.py &>/dev/null; then
    return 0
  else
    return 1
  fi
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

activate_pyenv_venv() {
  if ! have pyenv; then
    return 0
  fi

  local CURRENT_DIRECTORY=$(basename $PWD)

  # assumes venv is named after the current directory
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

  # if there's no pyenv venv for this directory, deactivate any venv sticking from a previous directory and be done
  if [[ ! -d "$PYENV_VENV" ]]; then
    # remove all pyenv paths from PATH (see: https://stackoverflow.com/a/62950499/8802485)
    export PATH=$(echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/')
    unset VIRTUAL_ENV
    return 0
  fi

  # its much faster to activate the venv directly instead of using the pyenv shell integration
  # see: https://stackoverflow.com/a/74290100/8802485
  # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
  source "${PYENV_VENV}/bin/activate"
}

# automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
update_python_env_vars
activate_pyenv_venv
