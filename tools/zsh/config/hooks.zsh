function chpwd() {
  activate_venv
}

# Keeps a line holding a literal secret out of the history file, and says how to pass it instead.
# A secret is the value after one of these markers:
#   - a flag ending in -key, -password, -secret or -token, such as --api-key or --access-token,
#     then `=` or spaces or tabs
#   - Bearer or bearer, then spaces or tabs
#   - a name ending in _TOKEN, _SECRET, _KEY or _PASSWORD, then `=`
# A value starting with $ is a reference, such as "$(secret get <name>)", and is saved as normal,
# except $'…', which is a literal. A value starting with ~, / or . is a path and is saved too.
# Other shapes are saved, such as a bare TOKEN=, a lowercase name or a secret inside a URL.
#
# Status 2 keeps the line for up-arrow in this shell but out of HISTFILE on every write zsh makes
# on its own. `fc -W` and `fc -A` write it anyway. The hook runs once per entered line: under
# 0.1 ms for a typed command, and a few milliseconds for a 40,000-character paste.
warn_secret_in_history() {
  emulate -L zsh
  setopt extended_glob
  local line="${1%%$'\n'}"
  # After the marker and its separator: an optional quote, or $' for a literal, then a character
  # that starts neither a reference nor a path
  local literal='([$]['\'']|["'\'']|)[^$"'\''[:blank:]~/.]'
  local marker=""
  # A flag or Bearer starts the line or follows a character that can't be part of it. Without that
  # anchor, every position in a long run of letters starts a new attempt, and a 20,000-character
  # paste takes tens of seconds.
  if [[ "${line}" == (#b)(|*[[:blank:]=])(--(|[a-z0-9-]#-)(key|password|secret|token))(=|[[:blank:]]##)${~literal}* ]]; then
    marker="${match[2]}"
  elif [[ "${line}" == (#b)(|*[^A-Za-z])([Bb]earer)[[:blank:]]##${~literal}* ]]; then
    marker="${match[2]}"
  # The search is for the fixed _TOKEN= and the like, and the name is read off the text before it,
  # since a pattern that matched the whole name would be tried from every letter of a long line
  elif [[ "${line}" == (#b)(*)_(TOKEN|SECRET|KEY|PASSWORD)=${~literal}* ]]; then
    marker="${(M)match[1]%%[A-Z0-9_]##}_${match[2]}"
  fi
  if [[ -n "${marker}" ]]; then
    print -u2 -r -- "⚠️  Not saved to history: it holds a secret after ${marker}. Store the secret" \
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
