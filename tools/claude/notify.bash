#!/usr/bin/env bash
# Claude Code's Notification hook: shows a card saying which session needs attention.
#
# Posts through terminal-notifier, so a click brings Ghostty forward and a new card replaces the
# folder's last one. Falls back to osascript when terminal-notifier is missing or refuses to post,
# so a card still appears. Every value reaches the poster as its own argument, never as code.
#
# terminal-notifier drops one leading backslash from a value and refuses a message starting with
# '-', '[', '(', '{' or a quote, so every message and subtitle gets a backslash in front. osascript
# reads an argument starting with '-' as an option unless '--' comes before it.
#
# settings.json runs this script by its repo path, not through a link in ~/.claude, so a pull
# changes the hook and the script together. A link would not exist until the next `symlinks`.
#
# Input: the hook's JSON on stdin. See https://code.claude.com/docs/en/hooks#notification
set -uo pipefail

input="$(cat)"

# Prints the string field `$1` of the input exactly, trailing newlines included, or nothing.
field() {
  local value
  value="$(jq -j --arg key "$1" '.[$key] // empty | strings' <<<"${input}" 2>/dev/null; printf x)"
  printf '%s' "${value%x}"
}

message="$(field message; printf x)"
message="${message%x}"
message="${message:-Needs your attention}"

folder="$(field cwd)"
folder="${folder:-${PWD}}"
name="${folder%"${folder##*[!/]}"}" # without trailing slashes
name="${name##*/}"

if command -v terminal-notifier >/dev/null 2>&1; then
  if refusal="$(terminal-notifier \
    -title "Claude Code" \
    -subtitle "\\${name}" \
    -message "\\${message}" \
    -group "claude-code:${folder}" \
    -activate com.mitchellh.ghostty 2>&1 >/dev/null)"; then
    exit 0
  fi
  printf 'terminal-notifier did not post, so falling back to osascript: %s\n' "${refusal}" >&2
fi

osascript \
  -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title "Claude Code" subtitle (item 2 of argv)' \
  -e 'end run' \
  -- "${message}" "${name}"
