#!/usr/bin/env bash
# Starts Claude Code with the permission mode for this machine, and with the folders related to the
# current repo added, so their CLAUDE.md files load too (shell.zsh exports
# CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD for that). A repo with no entry starts exactly as
# plain `claude --permission-mode <mode>`. The org's plans folder, where the next-step skill keeps
# each goal's plan, is added too whenever it exists.
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

# The folder holding the current repo's main checkout, so every worktree of a repo gets the same
# answer, or the current folder's parent outside a git repo
org_folder() {
  local common
  if common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    dirname "$(dirname "${common}")"
  else
    dirname "${PWD}"
  fi
}

# The org's plans folder, unless it is missing, is the current folder, or is one of the folders
# already added, which are passed as resolved paths
org_plans_dir() {
  local plans added
  plans="$(org_folder)/plans"
  [[ -d "${plans}" ]] || return 0
  plans="$(cd "${plans}" && pwd -P)"
  [[ "${plans}" != "$(pwd -P)" ]] || return 0
  for added in "$@"; do
    [[ "${plans}" != "${added}" ]] || return 0
  done
  printf '%s\n' "${plans}"
}

main() {
  local mode="bypassPermissions"
  if is_work; then
    mode="auto"
  fi

  local dirs=() added=() dir
  while IFS= read -r dir; do
    if [[ -d "${dir}" ]]; then
      dirs+=(--add-dir "${dir}")
      added+=("$(cd "${dir}" && pwd -P)")
      debug "📂 Adding ${dir}"
    else
      warn "⚠️ Skipping ${dir}, which is not cloned"
    fi
  done < <(related_dirs "$(basename "${PWD}")")

  # The guarded expansions keep an empty list from failing under bash 3.2's set -u
  local plans
  plans="$(org_plans_dir ${added[@]+"${added[@]}"})"
  if [[ -n "${plans}" ]]; then
    dirs+=(--add-dir "${plans}")
    debug "📂 Adding ${plans}"
  fi

  # The guarded expansion keeps an empty list from failing under bash 3.2's set -u
  exec claude --permission-mode "${mode}" ${dirs[@]+"${dirs[@]}"} "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
