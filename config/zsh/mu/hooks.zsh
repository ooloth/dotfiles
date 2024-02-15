function chpwd() {
  activate_venv
  set_gcloud_project_env_var
}

function precmd() {
  # will be set to "echo" if previous command was not "clear" or "c" (see preexec below)
  eval $PROMPT_COMMAND
}

function preexec() {
  # if cmd is not "clear" (or "c"), print a newline before the next prompt
  [[ "$1" == "clear" ]] || [[ "$1" == "c" ]] && export PROMPT_COMMAND="" || export PROMPT_COMMAND="echo"
}

activate_venv() {
  local CURRENT_DIRECTORY=$(basename $PWD)

  # assumes venv is named after the current directory
  local PYENV_VENV="${PYENV_ROOT}/versions/${CURRENT_DIRECTORY}"

  # if there's no pyenv venv for this directory, deactivate any venv sticking from a previous directory and be done
  if [[ ! -d "$PYENV_VENV" ]]; then
    export VIRTUAL_ENV=''
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

# FIXME: variable is being set even when not in a gcloud project
# TODO: only show in projects where the active project is relevant
function set_gcloud_project_env_var() {
  [[ ! $IS_WORK_LAPTOP ]] && return

  # if the gcloud command isn't found, do nothing
  command -v gcloud &> /dev/null || return

  # if GOOGLE_CLOUD_PROJECT is already set, do nothing
  [[ -n "$GOOGLE_CLOUD_PROJECT" ]] && [[ "$GOOGLE_CLOUD_PROJECT" != "(unset)" ]] && return

  # get current project (and don't output the result to the terminal)
  current_project=$(gcloud config get-value project 2> /dev/null)

  # if current_project is "(unset)", do nothing
  [[ "$current_project" == "(unset)" ]] && return

  # otherwise, set GOOGLE_CLOUD_PROJECT to the current gcloud project (for dap)
  export GOOGLE_CLOUD_PROJECT=$current_project
}

# automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
activate_venv

# automatically set GOOGLE_CLOUD_PROJECT when zsh first loads (called again in chwpd hook whenever cwd changes)
set_gcloud_project_env_var

