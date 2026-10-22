#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

# Available data: https://code.claude.com/docs/en/statusline#full-json-schema
model=$(echo "$input" | jq -r '.model.id // "claude"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')

# Context window: used tokens / total tokens, rounded to k
# used_percentage is authoritative (server-side); raw token sums overcounted due to cache fields
used_k=$(echo "$input" | jq -r '
  (.context_window.used_percentage // 0) *
  (.context_window.context_window_size // 200000) / 100000 | round
')
total_k=$(echo "$input" | jq -r '
  (.context_window.context_window_size // 200000) / 1000 | round
')
ctx="${used_k}k/${total_k}k"

# Color the context fraction based on tokens used: yellow >= 50k, red >= 100k
YELLOW=$'\033[33m'
RED=$'\033[31m'
RESET=$'\033[0m'

if [[ "$used_k" -ge 100 ]]; then
  color="$RED"
elif [[ "$used_k" -ge 50 ]]; then
  color="$YELLOW"
else
  color=""
fi

# The checkout root's name plus the path below it, so a linked worktree shows its own directory.
# git computes the prefix itself, which stays right when $dir reaches the checkout through a symlink.
if checkout=$(git -C "$dir" rev-parse --show-toplevel --show-prefix 2>/dev/null); then
  root=$(head -n 1 <<<"$checkout")
  prefix=$(sed -n 2p <<<"$checkout")
  location="$(basename "$root")${prefix:+/${prefix%/}}"
else
  location=$(basename "$dir")
fi

# Empty on a detached HEAD or outside a repo, which drops the separator and the branch
branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
branch_icon=$'\xee\x9c\xa5' # U+E725 nf-dev-git_branch, as in tools/tmux/config/gitmux.conf
# Two spaces after it, because Rex draws this glyph wider than one cell and covers a single space
folder_icon=$'\xef\x81\xbb' # U+F07B nf-fa-folder
left="${folder_icon}  ${location}${branch:+ · $branch_icon $branch}"

right_plain="${model} · ${ctx}"
right_rendered="${model} · ${color}${ctx}${color:+$RESET}"

# Claude Code indents the status line by 2 columns and cuts it off with "…" past COLUMNS - 4
edge_margin=4
gap=1
if [[ "${COLUMNS:-}" =~ ^[0-9]+$ ]]; then
  free=$((COLUMNS - edge_margin - ${#left} - ${#right_plain}))
  [[ "$free" -gt 1 ]] && gap="$free"
fi

printf "%s%*s%s\n" "$left" "$gap" "" "$right_rendered"
