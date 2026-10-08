#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead.

# Keep a COMPUTER that is already set to a known machine (interactive zsh exports it from the same
# computer name, and scripts/check-project-commands.bash sets it to choose a machine's branch).
# Detect it otherwise, including when it holds a value no is_* function recognises.
case "${COMPUTER:-}" in
  air | mini | work) ;;
  *)
    case "$(/usr/sbin/networksetup -getcomputername)" in
      "Air")  export COMPUTER="air" ;;
      "Mini") export COMPUTER="mini" ;;
      *)      export COMPUTER="work" ;;
    esac
    ;;
esac

is_air()  { [[ "${COMPUTER}" == "air" ]]; }
is_mini() { [[ "${COMPUTER}" == "mini" ]]; }
is_work() { [[ "${COMPUTER}" == "work" ]]; }
