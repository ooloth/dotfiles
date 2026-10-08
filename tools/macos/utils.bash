#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead.

# Keep a COMPUTER that is already set (interactive zsh exports it from the same computer name, and
# scripts/check-project-commands.bash sets it to choose a machine's branch). Detect it otherwise.
if [[ -z "${COMPUTER:-}" ]]; then
  case "$(/usr/sbin/networksetup -getcomputername)" in
    "Air")  export COMPUTER="air" ;;
    "Mini") export COMPUTER="mini" ;;
    *)      export COMPUTER="work" ;;
  esac
fi

is_air()  { [[ "${COMPUTER}" == "air" ]]; }
is_mini() { [[ "${COMPUTER}" == "mini" ]]; }
is_work() { [[ "${COMPUTER}" == "work" ]]; }
