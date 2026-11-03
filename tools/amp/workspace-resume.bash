#!/usr/bin/env bash
# The Resume Script in the michael-uloth Amp workspace (Workspace Settings > Orbs > Advanced). Amp
# runs it in every orb, in any project or none, when the orb starts and each time it wakes, before
# the agent starts. It gives every orb the shared skills, standards and CLAUDE.md. The setting holds
# a copy of this file, not a reference to it: paste it into that setting after changing it.
#
# Amp reads ~/.agents/skills and ~/.config/AGENTS.md when a thread starts, Claude Code threads
# included, and skills read ~/.agents/standards/ during a turn. Nothing reads the orb's ~/.claude.
#
# Amp waits at most 10 seconds for this script, so git gets 6. When the network fails, the copy
# already on disk is used.
set -euo pipefail

dotfiles="${HOME}/Repos/ooloth/dotfiles"
# A project that lists dotfiles as an additional repository gets this checkout before setup runs.
# Edits to it show in the thread's Changes pane, so it is the copy every link points at.
checkout="${HOME}/workspace/repos/dotfiles"

# Pull only a clean copy, and only fast-forward, so local edits are never overwritten
pull_if_clean() {
  if [[ -z "$(git -C "$1" status --porcelain)" ]]; then
    timeout 6 git -C "$1" pull --quiet --ff-only ||
      echo "dotfiles: pull failed, keeping the existing copy" >&2
  fi
}

if [[ -d "${checkout}" ]]; then
  pull_if_clean "${checkout}"
  # An orb that ran an earlier version of this script has its own clone here. Move it aside rather
  # than delete it, so an edit or commit nobody pushed is still there to recover.
  if [[ -d "${dotfiles}" && ! -L "${dotfiles}" ]]; then
    aside="${dotfiles}.replaced-$(date +%Y%m%d%H%M%S)"
    mv "${dotfiles}" "${aside}"
    echo "dotfiles: moved the earlier clone to ${aside}" >&2
  fi
  # Keeps ~/Repos/ooloth/dotfiles, which scripts and instructions name, working
  mkdir -p "$(dirname "${dotfiles}")"
  ln -sfn "${checkout}" "${dotfiles}"
  echo "linked ${dotfiles} to ${checkout}"
elif [[ -L "${dotfiles}" ]]; then
  # A dotfiles-project orb: its .agents/setup pointed this at the working checkout. Leave it alone.
  :
elif [[ -d "${dotfiles}/.git" ]]; then
  # A clone made by an earlier version of this script was shallow; give it full history once
  if [[ -z "$(git -C "${dotfiles}" status --porcelain)" && -f "${dotfiles}/.git/shallow" ]]; then
    timeout 6 git -C "${dotfiles}" fetch --quiet --unshallow ||
      echo "dotfiles: unshallow failed, keeping the shallow copy" >&2
  fi
  pull_if_clean "${dotfiles}"
else
  # No project, or a project without dotfiles as an additional repository. Full history, so agents
  # editing skills here can read git log and blame. It took 1 s here.
  mkdir -p "$(dirname "${dotfiles}")"
  timeout 6 git clone --quiet https://github.com/ooloth/dotfiles.git "${dotfiles}"
fi

DOTFILES="${dotfiles}" bash "${dotfiles}/tools/agents/link.bash"

# A link, not a copy: an edit to the checkout's CLAUDE.md applies to the next thread at once.
# symlink() in tools/bash/utils.bash keeps the source's name, so this uses ln.
mkdir -p "${HOME}/.config"
ln -sfn "${dotfiles}/tools/claude/config/CLAUDE.md" "${HOME}/.config/AGENTS.md"
echo "linked CLAUDE.md as ${HOME}/.config/AGENTS.md"
