function chpwd() {
  activate_venv
}

activate_venv() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  # assumes venv is named after the current directory
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

  # FIXME: support uv projects with a ".venv" directory, which don't require activating the venv
  # if there's no pyenv venv for this directory, deactivate any venv sticking from a previous directory and be done
  if [[ ! -d "$PYENV_VENV" ]]; then
    # remove all pyenv paths from PATH (see: https://stackoverflow.com/a/62950499/8802485)
    export PATH=`echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/'`
    unset VIRTUAL_ENV
    export PYTHONPATH=$HOME
    export MYPYPATH=$HOME
    return 0
  fi

  # its much faster to activate the venv directly instead of using the pyenv shell integration
  # see: https://stackoverflow.com/a/74290100/8802485
  # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
  source "${PYENV_VENV}/bin/activate"

  export PYTHONPATH=$PWD
  export MYPYPATH=$PWD
}

# automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
activate_venv
