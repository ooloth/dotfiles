#!/usr/bin/env bash
set -euo pipefail

# WARN: all helpers below are speculative (not used yet)

# Example usage:
#
# # Check if a package needs updating (fast)
# if is_formula_outdated "git"; then
#     echo "git is outdated, upgrading..."
#     brew upgrade --formula git
# else
#     echo "git is up to date"
# fi

# Ensure brew update has been run recently.
#
# Usage: ensure_brew_updated [hours] (default: 24)
# Returns: 0 if update is recent or was run, 1 if update failed
ensure_brew_updated() {
    local max_age_hours="${1:-24}"
    local timestamp_file="${TMPDIR:-/tmp}/.brew_last_update"
    local current_time
    current_time=$(date +%s)

    # Check if timestamp file exists and is recent enough
    if [[ -f "$timestamp_file" ]]; then
        local last_update
        last_update=$(cat "$timestamp_file" 2>/dev/null || echo "0")
        local age_seconds=$((current_time - last_update))
        local max_age_seconds=$((max_age_hours * 3600))

        if [[ $age_seconds -lt $max_age_seconds ]]; then
            return 0 # Update is recent enough
        fi
    fi

    # Run brew update and record timestamp
    echo "Running brew update (last update was more than ${max_age_hours}h ago)..." >&2
    if brew update >/dev/null 2>&1; then
        echo "$current_time" >"$timestamp_file"
        return 0
    else
        echo "Warning: brew update failed" >&2
        return 1
    fi
}

# Check if a formula is outdated (needs updating)
# Usage: is_formula_outdated "package-name"
# Returns: 0 if outdated, 1 if up-to-date, 2 if not installed
is_formula_outdated() {
    local formula="$1"

    if [[ -z "$formula" ]]; then
        echo "Error: Formula name required" >&2
        return 2
    fi

    # Check if formula is installed
    if ! brew list --formula "$formula" &>/dev/null; then
        return 2 # Not installed
    fi

    # Ensure brew is updated recently
    ensure_brew_updated || return 2

    # Use brew outdated with JSON for fastest checking
    local outdated_json=$(brew outdated --json=v2 --formula "$formula" 2>/dev/null) || return 2

    # If formula appears in outdated list, it needs updating
    if echo "${outdated_json}" | jq -e ".formulae[] | select(.name == \"$formula\")" &>/dev/null; then
        return 0 # Outdated
    else
        return 1 # Up-to-date
    fi
}
