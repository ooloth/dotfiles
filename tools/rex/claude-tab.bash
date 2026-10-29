#!/usr/bin/env bash
# Opens a Rex tab running Claude Code through cc.bash, so the tab's session gets this machine's
# permission mode and the repo's related folders exactly as `cc` would give them. The launcher
# never names a permission mode itself: cc.bash is the one place that decides it.
#
# Run with: claude-tab.bash [-s <session>] <tab name> <directory> [claude arguments]
# The tab opens in the first session labelled exactly Workers, which is created with this tab as its
# first window when none exists, unless -s names another session. Rex's JSON for the new tab, whose
# .block_ids[0] is the pane to capture, goes to stdout.
set -euo pipefail

cc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/claude/cc.bash"
workers="Workers"

usage() {
  printf 'Usage: %s [-s <session>] <tab name> <directory> [claude arguments]\n' \
    "$(basename "$0")" >&2
  exit 2
}

refuse() {
  printf '%s\n' "$1" >&2
  exit 2
}

# Prints the ID of the first session labelled exactly Workers, or nothing when there is none. Output
# that isn't a session list stops the launcher, so it can't be mistaken for "no Workers session".
find_workers() {
  local listed
  # bash 3.2 doesn't carry set -e into the $(find_workers) that calls this, so fail explicitly
  listed="$(rex session list --json)" || return
  printf '%s' "${listed}" |
    jq -r --arg label "${workers}" \
      '.sessions | map(select(.label == $label)) | .[0].session_id // ""'
}

main() {
  local session=""
  if [[ "${1:-}" == "-s" ]]; then
    [[ $# -ge 2 && -n "$2" ]] || usage
    session="$2"
    shift 2
  fi
  [[ $# -ge 2 ]] || usage
  local name="$1" dir="$2"
  shift 2

  if [[ -z "${session}" && -z "${REX_SESSION:-}" ]]; then
    refuse "REX_SESSION is not set; run from a Rex pane or pass -s <session>"
  fi
  [[ -d "${dir}" ]] || refuse "No such directory: ${dir}"
  [[ -f "${cc}" ]] || refuse "No cc.bash at ${cc}"
  dir="$(cd "${dir}" && pwd)"

  [[ -n "${session}" ]] || session="$(find_workers)"
  if [[ -n "${session}" ]]; then
    exec rex window new -s "${session}" "${name}" -c "${dir}" --json -- bash "${cc}" "$@"
  fi

  # A new session's JSON nests its first window, so print that window to match `window new`
  local created
  created="$(rex session new "${workers}" --window "${name}" -c "${dir}" --json -- bash "${cc}" "$@")"
  printf 'Created Rex session %s\n' "${workers}" >&2
  printf '%s' "${created}" |
    jq -ec '.initial_windows[0] | if .block_ids[0] then . else error("no pane in: \(.)") end'
}

main "$@"
