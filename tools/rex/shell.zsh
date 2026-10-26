##################
# SESSION SAVER #
##################

# Only in Rex panes, which Rex marks with REX_BLOCK. Elsewhere this file defines nothing.
if [[ -n "${REX_BLOCK:-}" ]]; then
  autoload -Uz add-zsh-hook
  zmodload -F zsh/stat b:zstat

  # Report the working directory to Rex (OSC 7) on every cd, so tools/rex/saver.py saves it at
  # once rather than at its next 30-second poll. Bytes outside a path's safe characters are
  # percent-encoded, as a file:// URL needs.
  _rex_osc7() {
    emulate -L zsh
    setopt extended_glob
    local LC_ALL=C char encoded=""
    local i
    for ((i = 1; i <= ${#PWD}; i++)); do
      char="${PWD[i]}"
      if [[ "${char}" == [A-Za-z0-9/._~-] ]]; then
        encoded+="${char}"
      else
        encoded+="$(printf '%%%02X' "'${char}")"
      fi
    done
    printf '\e]7;file://%s%s\e\\' "${HOST}" "${encoded}"
  }
  add-zsh-hook chpwd _rex_osc7
  _rex_osc7

  # Warn above the prompt when the saver is not running or reports a problem. A warning prints
  # once, and again only when it changes, so it does not repeat before every prompt. The saver
  # creates saver.log when it starts, so with no log there is nothing to point to, and the warning
  # says how to start it instead.
  _rex_restore_last_warning=""
  _rex_restore_check() {
    emulate -L zsh
    local dir="${REX_RESTORE_STATE_DIR:-${HOME}/.local/state/rex-restore}"
    local see_log=". See ${dir}/saver.log"
    local message="" running=false
    if [[ -f "${dir}/status.json" ]] &&
      ((EPOCHSECONDS - $(zstat +mtime "${dir}/status.json") <= 90)); then
      running=true
    fi
    if [[ "${running}" == false && ! -f "${dir}/saver.log" ]]; then
      message="the session saver has never started on this machine, so Rex sessions are not being"
      message+=" saved. Run \`u\`, then \`rex config reload\`"
    elif [[ "${running}" == false ]]; then
      message="the session saver is not running, so Rex sessions are not being saved${see_log}"
    elif [[ -s "${dir}/warning" ]]; then
      message="$(<"${dir}/warning")${see_log}"
    fi
    if [[ "${message}" != "${_rex_restore_last_warning}" ]]; then
      _rex_restore_last_warning="${message}"
      if [[ -n "${message}" ]]; then
        print -P "%F{red}⚠ Rex: ${message//\%/%%}%f"
      fi
    fi
  }
  zmodload zsh/datetime
  add-zsh-hook precmd _rex_restore_check
fi
