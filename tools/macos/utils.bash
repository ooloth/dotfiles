#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead.
# A COMPUTER the caller already set is kept, so a test can choose the machine.

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
