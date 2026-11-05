function chpwd() {
  activate_venv
}

# Keeps a line holding a literal secret out of the history file, and says how to pass it instead.
# A secret is a value after --api-key, --password, --token or "Bearer ", or assigned to a name
# ending in _TOKEN, _SECRET, _KEY or _PASSWORD. A value starting with $ is a reference, such as
# "$(secret get <name>)", and is saved as normal. Status 2 keeps the line for up-arrow in this
# shell but out of HISTFILE. It runs once per entered line, in about 60 µs.
warn_secret_in_history() {
  emulate -L zsh
  setopt extended_glob
  local line="${1%%$'\n'}"
  # After the marker and its separator, an optional quote and then a character that is not $
  local literal='([\"'\'']|)[^\$\"'\'' ]'
  if [[ "${line}" == (#b)*(--api-key|--password|--token|Bearer)([= ])${~literal}* ||
        "${line}" == (#b)*([A-Z0-9_]#_(TOKEN|SECRET|KEY|PASSWORD))=${~literal}* ]]; then
    print -u2 -r -- "⚠️  Not saved to history: it holds a secret after ${match[1]}. Store the secret" \
      "once with \`secret add <name>\`, then pass \"\$(secret get <name>)\" instead."
    return 2
  fi
  return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook zshaddhistory warn_secret_in_history

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
