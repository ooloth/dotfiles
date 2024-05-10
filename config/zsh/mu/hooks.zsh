function chpwd() {
  activate_venv
  set_gcloud_project_env_var
}

function precmd() {
  # will be set to "echo" if previous command was not "clear" or "c" (see preexec below)
  eval $PROMPT_COMMAND
}

function preexec() {
  # TODO: if I keep tmux at the top, just statically set the prompt command to "echo"
  export PROMPT_COMMAND="echo"
  # if cmd is not "clear" (or "c"), print a newline before the next prompt
  # [[ "$1" == "clear" ]] || [[ "$1" == "c" ]] && export PROMPT_COMMAND="" || export PROMPT_COMMAND="echo"
}

activate_venv() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  # assumes venv is named after the current directory
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

  # if there's no pyenv venv for this directory, deactivate any venv sticking from a previous directory and be done
  if [[ ! -d "$PYENV_VENV" ]]; then
    # remove all pyenv paths from PATH (see: https://stackoverflow.com/a/62950499/8802485)
    export PATH=`echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/'`
    unset VIRTUAL_ENV
    export PYTHONPATH=$HOME
    export MYPYPATH=$HOME
    return
  fi

  # its much faster to activate the venv directly instead of using the pyenv shell integration
  # see: https://stackoverflow.com/a/74290100/8802485
  # see: https://stackoverflow.com/questions/45554864/why-am-i-getting-permission-denied-when-activating-a-venv
  source "${PYENV_VENV}/bin/activate"

  export PYTHONPATH=$PWD
  export MYPYPATH=$PWD
}

# This enhances starship + helps prevent silly mistakes in projects that rely on gcloud
set_gcloud_project_env_var() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  case $CURRENT_DIRECTORY in
    dash-phenoapp-v2) export GOOGLE_CLOUD_PROJECT='eng-infrastructure' ;;
    *)                unset GOOGLE_CLOUD_PROJECT ;;
  esac
}

# automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
activate_venv

# automatically set GOOGLE_CLOUD_PROJECT when zsh first loads (called again in chwpd hook whenever cwd changes)
set_gcloud_project_env_var
