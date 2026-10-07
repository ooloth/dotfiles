#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead.

# Keep a COMPUTER that is already set to a known machine, so a caller can choose which machine's
# branch a script takes. Any other value is replaced by detection, so a stray one cannot turn
# is_work off on a work machine. Interactive zsh exports the same value from the same computer name
# (tools/macos/shell.zsh).
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
