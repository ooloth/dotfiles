#!/usr/bin/env bash
set -euo pipefail

export DOTFILES="${HOME}/Repos/ooloth/dotfiles"
export DOTFILES_CHECK=true

source "${DOTFILES}/tools/bash/utils.bash"

failures=0

info "🔍 Checking dotfiles"

# ─── Symlinks ───────────────────────────────────────────────

printf "\nSymlinks\n\n"

link_files=$(find "${DOTFILES}/tools" \
  -type d \( -name "@new" -o -name "@archive" \) -prune \
  -o -type f -name "link.bash" -print | sort -t/ -k5)

for file in $link_files; do
  bash "$file" || failures=$((failures + 1))
done

# ─── Tool presence ──────────────────────────────────────────

printf "\nTools\n\n"

check_tool() {
  local name="$1"
  if command -v "$name" &>/dev/null; then
    printf "✅ OK      %s\n" "$name"
  else
    printf "❌ %s\n" "$name"
    failures=$((failures + 1))
  fi
}

check_tool brew
check_tool git
check_tool zsh
check_tool mise
check_tool nvim
check_tool tmux
check_tool rg
check_tool fd
check_tool bat
check_tool eza
check_tool fzf
check_tool gh

# ─── Summary ────────────────────────────────────────────────

if [[ $failures -eq 0 ]]; then
  info "✅ All checks passed"
else
  error "❌ ${failures} check(s) failed"
  exit 1
fi
