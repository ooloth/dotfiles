#!/usr/bin/env bash
# Checks every update prerequisite before `u` changes anything (docs/decisions/002 to 004).
# Runs the network check and each tools/{tool}/preflight.bash at once, or only one tool's when
# given a tool name, and exits 1 after reporting every check that failed or ran out of time.
# Written for macOS's own bash 3.2, with no `timeout`, which only Homebrew's coreutils provides.
set -uo pipefail

# In case this file is sourced before shell variables have been symlinked
export DOTFILES="${HOME}/Repos/ooloth/dotfiles"

source "${DOTFILES}/tools/bash/utils.bash"

deadline_seconds=5

check_network() {
  if ! curl --silent --head --fail --max-time "${deadline_seconds}" --output /dev/null https://formulae.brew.sh; then
    echo "Every update downloads something, and formulae.brew.sh did not answer. Check your connection or VPN." >&2
    return 1
  fi
}

main() {
  local tool="${1:-}"
  # Global, because the EXIT trap runs after main's locals are gone
  results="$(mktemp -d)"
  trap 'rm -rf "${results}"' EXIT

  local names=() pids=()

  check_network >"${results}/network" 2>&1 &
  names+=("network")
  pids+=($!)

  local file name
  for file in "${DOTFILES}"/tools/*/preflight.bash; do
    [[ -f "${file}" ]] || continue
    name="$(basename "$(dirname "${file}")")"
    [[ "${name}" == @* ]] && continue
    [[ -n "${tool}" && "${name}" != "${tool}" ]] && continue
    bash "${file}" >"${results}/${name}" 2>&1 &
    names+=("${name}")
    pids+=($!)
  done

  # Poll rather than wait, so one hung check can't hold up the deadline for the rest
  # Timed by the clock, not by counting polls, so a slow machine can't stretch the deadline.
  # SECONDS counts whole seconds, so <= gives every check its full deadline and under 1 s more.
  local i running start=${SECONDS}
  while ((SECONDS - start <= deadline_seconds)); do
    running=0
    for i in "${!pids[@]}"; do
      kill -0 "${pids[i]}" 2>/dev/null && running=1
    done
    ((running)) || break
    sleep 0.1
  done

  local failures=() status
  for i in "${!pids[@]}"; do
    if kill -0 "${pids[i]}" 2>/dev/null; then
      pkill -P "${pids[i]}" 2>/dev/null
      kill "${pids[i]}" 2>/dev/null
      wait "${pids[i]}" 2>/dev/null
      failures+=("${names[i]}: timed out after ${deadline_seconds}s")
      continue
    fi
    wait "${pids[i]}"
    status=$?
    if ((status != 0)); then
      failures+=("${names[i]}: $(cat "${results}/${names[i]}")")
    fi
  done

  if [[ ${#failures[@]} -gt 0 ]]; then
    error "❌ Nothing was updated: fix these first"
    printf '  - %s\n' "${failures[@]}" >&2
    printf '\n' >&2
    return 1
  fi
}

main "$@"
