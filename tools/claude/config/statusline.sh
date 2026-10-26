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

# Color the context fraction by tokens used: yellow from 125k, red from 250k, where measured
# long-context quality stops being near its best and then clearly drops. Quality follows the token
# count, not the share of the window, so the thresholds only shrink to half and three quarters of a
# window too small to reach them, which still warns before the window fills.
GREEN=$'\033[32m'
CYAN=$'\033[36m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
RESET=$'\033[0m'

yellow_k=$((total_k / 2 < 125 ? total_k / 2 : 125))
red_k=$((total_k * 3 / 4 < 250 ? total_k * 3 / 4 : 250))

if [[ "$used_k" -ge "$red_k" ]]; then
  color="$RED"
elif [[ "$used_k" -ge "$yellow_k" ]]; then
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

# Commits ahead of and behind the upstream as of the last fetch, then the lines inserted and deleted
# by staged and unstaged changes against HEAD. git gives nothing here without an upstream or a first
# commit, and each count is dropped when it is zero.
divergence=$(git -C "$dir" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null || true)
read -r behind ahead <<<"$divergence" || true
shortstat=$(git -C "$dir" diff HEAD --shortstat 2>/dev/null || true)
insertions=$(sed -nE 's/.* ([0-9]+) insertions?\(\+\).*/\1/p' <<<"$shortstat")
deletions=$(sed -nE 's/.* ([0-9]+) deletions?\(-\).*/\1/p' <<<"$shortstat")

stats_plain=""
stats_rendered=""
append_stat() {
  local count=$1 symbol=$2 colour=$3
  [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]] || return 0
  stats_plain+=" ${symbol}${count}"
  stats_rendered+=" ${colour}${symbol}${count}${colour:+$RESET}"
}
append_stat "${ahead:-}" "↑" "$CYAN"
append_stat "${behind:-}" "↓" "$CYAN"
append_stat "$insertions" "+" "$GREEN"
append_stat "$deletions" "-" "$RED"

# On a detached HEAD the counts follow the location directly
git_plain="${branch:+$branch_icon $branch}${stats_plain}"
git_rendered="${branch:+$branch_icon $branch}${stats_rendered}"
git_plain="${git_plain# }"
git_rendered="${git_rendered# }"
left_plain="${folder_icon}  ${location}${git_plain:+ · $git_plain}"
left_rendered="${folder_icon}  ${location}${git_rendered:+ · $git_rendered}"

right_plain="${model} · ${ctx}"
right_rendered="${model} · ${color}${ctx}${color:+$RESET}"

# Claude Code indents the status line by 2 columns and cuts it off with "…" past COLUMNS - 4
edge_margin=4
gap=1
if [[ "${COLUMNS:-}" =~ ^[0-9]+$ ]]; then
  free=$((COLUMNS - edge_margin - ${#left_plain} - ${#right_plain}))
  [[ "$free" -gt 1 ]] && gap="$free"
fi

printf "%s%*s%s\n" "$left_rendered" "$gap" "" "$right_rendered"
