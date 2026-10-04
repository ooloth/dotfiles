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

# ─── Agent shell ────────────────────────────────────────────
# Claude Code copies the interactive shell's aliases and functions into the shell its agents use, so
# any that redefine a standard name (test, ls, kill, env, ...) silently change what agents run. The
# end of .zshrc removes them when CLAUDECODE is set. These start a real interactive zsh each way.

printf "\nAgent shell\n\n"

# Prints the output of a command run in an interactive zsh, with CLAUDECODE set (agent) or unset (human)
in_zsh() {
  local who="$1" script="$2"
  if [[ "$who" == "agent" ]]; then
    env CLAUDECODE=1 zsh -i -c "$script" 2>/dev/null
  else
    env -u CLAUDECODE zsh -i -c "$script" 2>/dev/null
  fi
}

report() {
  local ok="$1" label="$2" detail="${3:-}"
  if [[ "$ok" == "true" ]]; then
    printf "✅ OK      %s\n" "$label"
  else
    printf "❌ %s%s\n" "$label" "${detail:+: ${detail}}"
    failures=$((failures + 1))
  fi
}

# shellcheck disable=SC2016 # the scripts below are expanded by zsh, not here
agent_aliases=$(in_zsh agent 'print -r -- ${#aliases}' | tail -n 1 || true)
report "$([[ "$agent_aliases" == "0" ]] && echo true)" "agent shell has no aliases" "${agent_aliases} defined"

# shellcheck disable=SC2016
shadowing=$(in_zsh agent 'for f in ${(k)functions}; do (( $+builtins[$f] || $+commands[$f] )) && print -r -- $f; done' | sort | tr '\n' ' ' || true)
report "$([[ -z "$shadowing" ]] && echo true)" "agent shell has no function named like a command" "$shadowing"

# shellcheck disable=SC2016
human_aliases=$(in_zsh human 'print -r -- ${#aliases}' | tail -n 1 || true)
report "$([[ "$human_aliases" =~ ^[0-9]+$ && "$human_aliases" -gt 0 ]] && echo true)" "human shell keeps its aliases" "${human_aliases:-none} defined"

# shellcheck disable=SC2016
report "$(in_zsh human 'ls "$DOTFILES" >/dev/null' && echo true)" "ls accepts a path in the human shell"

# ─── Feature aliases ────────────────────────────────────────
# An alias defined in features/<name>/shell.zsh that runs a script under features/ runs one of its
# own feature's scripts, so two features' aliases cannot be swapped unnoticed.

printf "\nFeature aliases\n\n"

for file in "${DOTFILES}"/features/*/shell.zsh; do
  feature=$(basename "$(dirname "$file")")
  while IFS= read -r line; do
    name=$(sed -E 's/^alias ([^=]+)=.*/\1/' <<<"$line")
    target=$(sed -E 's|.*/features/([^/]+)/.*|\1|' <<<"$line")
    report "$([[ "$target" == "$feature" ]] && echo true)" "${feature}: ${name}" "runs a script from features/${target}"
  done < <(grep -E '^alias [^=]+=.*/features/[^/]+/' "$file" || true)
done

# ─── Summary ────────────────────────────────────────────────

if [[ $failures -eq 0 ]]; then
  info "✅ All checks passed"
else
  error "❌ ${failures} check(s) failed"
  exit 1
fi
