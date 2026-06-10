#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

# Available data: https://code.claude.com/docs/en/statusline#full-json-schema
model=$(echo "$input" | jq -r '.model.id // "claude"')
agent=$(echo "$input" | jq -r '.agent.name // ""')

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

# Color the context fraction based on usage: yellow >= 50%, red >= 75%
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

if [[ "$used_k" -ge 100 ]]; then
  color="$RED"
elif [[ "$used_k" -ge 50 ]]; then
  color="$YELLOW"
else
  color=""
fi

middle="${model}${agent:+ · $agent}"

if [[ -n "$color" ]]; then
  printf "%s · ${color}%s${RESET}\n" "$middle" "$ctx"
else
  printf "%s · %s\n" "$middle" "$ctx"
fi
