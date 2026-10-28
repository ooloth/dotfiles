#!/usr/bin/env bash
# Starts Claude Code with the permission mode for this machine, told where the repos related to the
# current repo are cloned. A repo with no entry starts exactly as plain
# `claude --permission-mode <mode>`. The org's plans folder, where the next-step skill keeps each
# goal's plan, is added whenever it exists.
#
# Related repos are named in the system prompt rather than added with --add-dir, because a clone is
# a working checkout that may be on any branch: adding it would load its CLAUDE.md and present its
# files as current, while a hint lets the session check before relying on it.
#
# Run with: cc [claude arguments], or ccc to continue the last session
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../bash/utils.bash"

# Repos a session in the named repo should be told about, one name per line, each cloned beside
# the current repo's main checkout
related_repos() {
  if is_work; then
    case "$1" in
    # mapapp-1 | mapapp-2 | mapapp-3) printf '%s\n' mapapp-infra ;;
    # The prefixes match each repo's worktrees and clones beside it too
    react-clinops-siteoutreach*) printf '%s\n' bc-eng-clinical ;;
    bc-eng-clinical*) printf '%s\n' react-clinops-siteoutreach ;;
    *) ;;
    esac
  else
    case "$1" in
    # media) printf '%s\n' media-ops ;;
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

# The org's plans folder, unless it is missing or is the current folder
org_plans_dir() {
  local plans
  plans="$(org_folder)/plans"
  [[ -d "${plans}" ]] || return 0
  plans="$(cd "${plans}" && pwd -P)"
  [[ "${plans}" != "$(pwd -P)" ]] || return 0
  printf '%s\n' "${plans}"
}

# The system prompt line about one related repo, given its name and where it should be cloned
# shellcheck disable=SC2016 # The backticks are markdown for the session, not command substitution
related_repo_hint() {
  local name="$1" path="$2"
  if [[ ! -d "${path}" ]]; then
    printf 'Related repo: `%s` is not cloned at `%s`.\n' "${name}" "${path}"
    return 0
  fi
  printf 'Related repo: `%s` at `%s`. It is a working checkout that may be on a feature branch or behind origin. To read origin'\''s current default branch, run `git -C <path> fetch origin` and then `git -C <path> show origin/HEAD:<file>`. Don'\''t change its branch or files; to change that repo, add a worktree beside it.\n' \
    "${name}" "${path}"
}

main() {
  local mode="bypassPermissions"
  if is_work; then
    mode="auto"
  fi

  local claude_args=() plans
  plans="$(org_plans_dir)"
  if [[ -n "${plans}" ]]; then
    claude_args+=(--add-dir "${plans}")
    debug "📂 Adding ${plans}"
  fi

  local org hints="" name
  org="$(org_folder)"
  while IFS= read -r name; do
    hints+="$(related_repo_hint "${name}" "${org}/${name}")"$'\n'
  done < <(related_repos "$(basename "${PWD}")")
  if [[ -n "${hints}" ]]; then
    claude_args+=(--append-system-prompt "${hints%$'\n'}")
  fi

  # The guarded expansion keeps an empty list from failing under bash 3.2's set -u
  exec claude --permission-mode "${mode}" ${claude_args[@]+"${claude_args[@]}"} "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
