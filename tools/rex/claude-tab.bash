#!/usr/bin/env bash
# Opens a Rex tab running Claude Code through cc.bash, so the tab's session gets this machine's
# permission mode and the repo's related folders exactly as `cc` would give them. The launcher
# never names a permission mode itself: cc.bash is the one place that decides it.
#
# Run with: claude-tab.bash [-s <session>] <tab name> <directory> [claude arguments]
# The tab opens in $REX_SESSION unless -s names another session. Rex's JSON for the new tab, whose
# .block_ids[0] is the pane to capture, goes to stdout.
set -euo pipefail

cc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/claude/cc.bash"

usage() {
  printf 'Usage: %s [-s <session>] <tab name> <directory> [claude arguments]\n' \
    "$(basename "$0")" >&2
  exit 2
}

refuse() {
  printf '%s\n' "$1" >&2
  exit 2
}

main() {
  local session="${REX_SESSION:-}"
  if [[ "${1:-}" == "-s" ]]; then
    [[ $# -ge 2 ]] || usage
    session="$2"
    shift 2
  fi
  [[ $# -ge 2 ]] || usage
  local name="$1" dir="$2"
  shift 2

  [[ -n "${session}" ]] || refuse "REX_SESSION is not set; run from a Rex pane or pass -s <session>"
  [[ -d "${dir}" ]] || refuse "No such directory: ${dir}"
  [[ -f "${cc}" ]] || refuse "No cc.bash at ${cc}"

  exec rex window new -s "${session}" "${name}" -c "$(cd "${dir}" && pwd)" --json \
    -- bash "${cc}" "$@"
}

main "$@"
