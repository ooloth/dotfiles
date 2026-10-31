#!/usr/bin/env bash
# The Resume Script in the michael-uloth Amp workspace (Workspace Settings > Orbs > Advanced). Amp
# runs it in every orb, in any project or none, when the orb starts and each time it wakes, before
# the agent starts. It gives every orb the shared skills, standards and CLAUDE.md, at the version
# last pushed to main. This file is the source: paste it into that setting after changing it.
#
# Amp reads ~/.agents/skills and ~/.config/AGENTS.md when a thread starts, Claude Code threads
# included, and skills read ~/.agents/standards/ during a turn. Nothing reads the orb's ~/.claude.
#
# Amp waits at most 10 seconds for this script, so git gets 6. When the network fails, the copy
# already on disk is used.
set -euo pipefail

dotfiles="${HOME}/Repos/ooloth/dotfiles"
if [[ -L "${dotfiles}" ]]; then
  # A dotfiles-project orb: its .agents/setup pointed this at the working checkout. Leave it alone.
  :
elif [[ -d "${dotfiles}/.git" ]]; then
  # Pull only a clean copy, and only fast-forward, so local edits are never overwritten
  if [[ -z "$(git -C "${dotfiles}" status --porcelain)" ]]; then
    # A clone made by an earlier version of this script was shallow; give it full history once
    if [[ -f "${dotfiles}/.git/shallow" ]]; then
      timeout 6 git -C "${dotfiles}" fetch --quiet --unshallow ||
        echo "dotfiles: unshallow failed, keeping the shallow copy" >&2
    fi
    timeout 6 git -C "${dotfiles}" pull --quiet --ff-only ||
      echo "dotfiles: pull failed, keeping the existing copy" >&2
  fi
else
  # Full history, so agents editing skills here can read git log and blame. It took 1 s here.
  mkdir -p "$(dirname "${dotfiles}")"
  timeout 6 git clone --quiet https://github.com/ooloth/dotfiles.git "${dotfiles}"
fi

DOTFILES="${dotfiles}" bash "${dotfiles}/tools/agents/link.bash"

# A link, not a copy: in a dotfiles-project orb, an edit to the checkout's CLAUDE.md applies to the
# next thread at once. symlink() in tools/bash/utils.bash keeps the source's name, so this uses ln.
mkdir -p "${HOME}/.config"
ln -sfn "${dotfiles}/tools/claude/config/CLAUDE.md" "${HOME}/.config/AGENTS.md"
echo "linked CLAUDE.md as ${HOME}/.config/AGENTS.md"
