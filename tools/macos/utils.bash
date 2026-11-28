#!/usr/bin/env bash

# Machine detection for bash scripts.
# For zsh sessions, see tools/macos/shell.zsh instead. For Brewfiles, see tools/macos/computer.rb.
# A COMPUTER the caller already set is kept, so a test can choose the machine. An Amp orb, which
# sets AMP_ORB=1, is never for work, so it is "orb" rather than any Mac.

if [[ -z "${COMPUTER:-}" && "${AMP_ORB:-}" == "1" ]]; then
  export COMPUTER="orb"
elif [[ -z "${COMPUTER:-}" ]]; then
  # networksetup exists only on macOS. Elsewhere the name is empty, so "work".
  case "$([[ -x /usr/sbin/networksetup ]] && /usr/sbin/networksetup -getcomputername)" in
    "Air")  export COMPUTER="air" ;;
    "Mini") export COMPUTER="mini" ;;
    *)      export COMPUTER="work" ;;
  esac
fi

is_air()  { [[ "${COMPUTER}" == "air" ]]; }
is_mini() { [[ "${COMPUTER}" == "mini" ]]; }
is_work() { [[ "${COMPUTER}" == "work" ]]; }
is_orb()  { [[ "${COMPUTER}" == "orb" ]]; }
