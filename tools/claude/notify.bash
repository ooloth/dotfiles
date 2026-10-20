#!/usr/bin/env bash
# Claude Code's Notification hook: shows a card saying which session needs attention.
#
# Posts through osascript, not terminal-notifier. macOS sets the alert style once per app, and
# hub-daemon needs terminal-notifier set to Alerts, so a card posted through it would stay on
# screen until dismissed. osascript's cards come from Script Editor, which is set to Banners.
#
# The message and folder reach AppleScript as arguments, never as code. '--' stops osascript
# reading a message that starts with '-' as one of its own options.
#
# settings.json runs this script by its repo path, not through a link in ~/.claude, so a pull
# changes the hook and the script together. A link would not exist until the next `symlinks`.
#
# Input: the hook's JSON on stdin. See https://code.claude.com/docs/en/hooks#notification
set -uo pipefail

input="$(cat)"
message="$(jq -r '.message // empty' <<<"${input}" 2>/dev/null)"
folder="$(jq -r '.cwd // empty' <<<"${input}" 2>/dev/null)"

osascript \
  -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title "Claude Code" subtitle (item 2 of argv)' \
  -e 'end run' \
  -- "${message:-Needs your attention}" "$(basename "${folder:-${PWD}}")"
