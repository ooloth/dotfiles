#!/usr/bin/env bash
# Claude Code's Notification hook: shows a one-line card saying which session needs attention.
#
# Posts through osascript, not terminal-notifier. macOS sets the alert style once per app, and
# hub-daemon needs terminal-notifier set to Alerts, so a card posted through it would stay on
# screen until dismissed. osascript's cards come from Script Editor, which is set to Banners.
#
# Claude Code runs the hook in the session's folder, so $PWD names it and the JSON on stdin is
# not read. The text reaches AppleScript as an argument, never as code, and '--' stops osascript
# reading it as one of its own options.
#
# settings.json runs this script by its repo path, not through a link in ~/.claude, so a pull
# changes the hook and the script together. A link would not exist until the next `symlinks`.
set -uo pipefail

osascript \
  -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title "Claude Code"' \
  -e 'end run' \
  -- "Needs your attention in $(basename "${PWD}")"
