#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead.

case "$(/usr/sbin/networksetup -getcomputername)" in
  "Air")  export COMPUTER="air" ;;
  "Mini") export COMPUTER="mini" ;;
  *)      export COMPUTER="work" ;;
esac

is_air()  { [[ "${COMPUTER}" == "air" ]]; }
is_mini() { [[ "${COMPUTER}" == "mini" ]]; }
is_work() { [[ "${COMPUTER}" == "work" ]]; }
