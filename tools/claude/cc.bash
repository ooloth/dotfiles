#!/usr/bin/env bash
# Starts Claude Code with the permission mode for this machine, and with the folders related to the
# current repo added, so their CLAUDE.md files load too (shell.zsh exports
# CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD for that). A repo with no entry starts exactly as
# plain `claude --permission-mode <mode>`.
#
# Run with: cc [claude arguments], or ccc to continue the last session
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../bash/utils.bash"

# Folders a session in the named repo should also load, one per line, relative to that repo
related_dirs() {
  if is_work; then
    case "$1" in
    # mapapp-1 | mapapp-2 | mapapp-3) printf '%s\n' ../mapapp-infra ;;
    *) ;;
    esac
  else
    case "$1" in
    # media) printf '%s\n' ../media-ops ;;
    *) ;;
    esac
  fi
}

main() {
  local mode="bypassPermissions"
  if is_work; then
    mode="auto"
  fi

  local dirs=() dir
  while IFS= read -r dir; do
    if [[ -d "${dir}" ]]; then
      dirs+=(--add-dir "${dir}")
      debug "📂 Adding ${dir}"
    else
      warn "⚠️ Skipping ${dir}, which is not cloned"
    fi
  done < <(related_dirs "$(basename "${PWD}")")

  # The guarded expansion keeps an empty list from failing under bash 3.2's set -u
  exec claude --permission-mode "${mode}" ${dirs[@]+"${dirs[@]}"} "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
