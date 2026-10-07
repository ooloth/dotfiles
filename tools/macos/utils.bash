#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead.

# A COMPUTER that is already set wins, so a caller can choose which machine's branch a script
# takes. Interactive zsh exports it from the same computer name (tools/macos/shell.zsh).
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
