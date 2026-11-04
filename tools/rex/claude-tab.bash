#!/usr/bin/env bash
# Opens a Rex tab running Claude Code through cc.bash, so the tab's session gets this machine's
# permission mode and the repo's related folders exactly as `cc` would give them. The launcher
# never names a permission mode itself: cc.bash is the one place that decides it.
#
# Run with: claude-tab.bash [-s <session>] <tab name> <directory> [claude arguments]
# Unless -s names a session, the tab opens in the first session labelled exactly
# `Workers (<repo>)`, where <repo> is the name the directory's origin remote ends in, or `Workers`
# outside a repository (decision 011). That session is created with this tab as its first window
# when none exists. Rex's JSON for the new tab goes to stdout: .block_ids[0] is the pane to capture,
# and .session_id the session to capture it from.
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

# Prints the label of the session a tab for this directory belongs in: `Workers (<repo>)`, where
# <repo> is the last path segment of the origin remote's URL without .git, so every checkout and
# worktree of one repository shares a session whatever its folder is called. A directory outside a
# repository, with no origin, or whose URL ends in no name, gets plain Workers.
session_label() {
  local url name
  url="$(git -C "$1" remote get-url origin 2>/dev/null)" || {
    printf '%s' "${workers}"
    return
  }
  # The loop ends because each pass shortens the URL by one character
  while [[ "${url}" == */ ]]; do url="${url%/}"; done
  name="${url##*[/:]}"
  name="${name%.git}"
  if [[ -z "${name}" ]]; then
    printf '%s' "${workers}"
    return
  fi
  printf '%s (%s)' "${workers}" "${name}"
}

# Prints the ID of the first session labelled exactly $1, or nothing when there is none. Output that
# isn't a session list stops the launcher, so it can't be mistaken for "no such session".
find_session() {
  local listed
  # bash 3.2 doesn't carry set -e into the $(find_session) that calls this, so fail explicitly
  listed="$(rex session list --json)" || return
  printf '%s' "${listed}" |
    jq -r --arg label "$1" '.sessions | map(select(.label == $label)) | .[0].session_id // ""'
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

  local label=""
  if [[ -z "${session}" ]]; then
    label="$(session_label "${dir}")"
    session="$(find_session "${label}")"
  fi
  if [[ -n "${session}" ]]; then
    # Rex.app keeps showing its tab when the server's focus moves, and sends key bindings to the
    # server's focused pane. A new tab that took focus would get every key pressed in the tab still
    # on screen, such as cmd+g opening lazygit out of sight, so it leaves focus where it was.
    local opened
    opened="$(rex window new -s "${session}" "${name}" -c "${dir}" --focus=false --json -- bash "${cc}" "$@")"
    # A tab printed without a pane would leave the caller capturing `-b ""`, which is its own pane
    printf '%s' "${opened}" |
      jq -ec --arg session "${session}" \
        'if .window_id and .block_ids[0] then . + {session_id: $session} else error("no pane in: \(.)") end'
    return
  fi

  # A new session's JSON nests its first window, so print that window to match `window new`
  [[ -n "${label}" ]] || refuse "BUG: no session label to create a session with"
  local created
  created="$(rex session new "${label}" --window "${name}" -c "${dir}" --json -- bash "${cc}" "$@")"
  printf 'Created Rex session %s\n' "${label}" >&2
  printf '%s' "${created}" |
    jq -ec '.session_id as $session | .initial_windows[0] |
      if .block_ids[0] and ($session | type == "string" and length > 0)
      then . + {session_id: $session}
      else error("no pane or session in: \(.)") end'
}

main "$@"
