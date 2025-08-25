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
  local CURRENT_DIRECTORY="${PWD}"
  local VENV=""

  # Function to find the nearest virtual environment
  find_venv() {
    local dir="$1" # start from the current directory
    while [ "$dir" != "/" ]; do # don't go past the root directory
      local uv_venv_default="$dir/.venv"
      local uv_venv_roadie="$dir/venv"
      if [ -f "$uv_venv_default/bin/activate" ]; then
        echo "$uv_venv_default"
        return
      elif [ -f "$uv_venv_roadie/bin/activate" ]; then
        echo "$uv_venv_roadie"
        return
      fi
      dir="$(dirname "$dir")" # move up one directory and try again
    done
  }

  VENV=$(find_venv "$CURRENT_DIRECTORY")

  if [ -n "$VENV" ]; then
    source "${VENV}/bin/activate"
  else
    # Deactivate any venv sticking from a previous directory and be done
    if [ -n "${VIRTUAL_ENV}" ] && command -v deactivate >/dev/null 2>&1; then
      deactivate
    fi
    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    # remove all pyenv paths from PATH (see: https://stackoverflow.com/a/62950499/8802485)
    export PATH=$(echo $PATH | tr ':' '\n' | sed '/pyenv/d' | tr '\n' ':' | sed -r 's/:$/\n/')
  fi
}

# Automatically activate appropriate venv when zsh first loads (called again in chpwd hook whenever cwd changes)
update_python_env_vars
activate_venv
