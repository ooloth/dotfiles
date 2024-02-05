function chpwd() {
  activate_venv
}

activate_venv() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  # assumes venv is named after the current directory
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

  # if there's no pyenv venv for this directory, deactivate any venv sticking from a previous directory and be done
  if [[ ! -d "$PYENV_VENV" ]]; then
    export VIRTUAL_ENV=''
    return
  fi

  # its much faster to activate the venv directly and not use the pyenv shell integration at all ("pyenv init" + "pyenv shell <venv>")
  # see: https://stackoverflow.com/a/74290100/8802485
  # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
  source "${PYENV_VENV}/bin/activate"
}

# automatically activate appropriate venv when zsh first loads (called again in autocommands.zsh whenever cwd changes)
activate_venv

