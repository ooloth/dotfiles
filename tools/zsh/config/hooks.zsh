function chpwd() {
  activate_venv
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
activate_venv
