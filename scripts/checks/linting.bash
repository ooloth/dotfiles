#!/usr/bin/env bash
# Lints every file a linter covers, and fails after running them all if any found a problem.
#
# Run with: bash scripts/checks/linting.bash
#
# Python: ruff check, with rules from ruff.toml at the root.
# Shell: shellcheck on every *.sh and *.bash file outside hidden directories, several at a time,
# with settings from .shellcheckrc.
# zsh utils: tools/zsh/utils.zsh parses as bash, because features/setup/wip/setup.bash sources it.
# Skills: every shared skill's SKILL.md frontmatter parses, and no file in a skill names a fixed
# temp path (tools/agents/check-skills.py).
# Each fails when it finds nothing to check.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${DOTFILES}/scripts/checks/versions.bash"
cd "${DOTFILES}" || exit 1

failed=()

if [[ -z "$(find . -name '*.py' -not -path '*/__pycache__/*' -print -quit)" ]]; then
  echo "No Python files found, so ruff would check nothing." >&2
  failed+=("ruff check")
else
  echo "== ruff check"
  uv run --quiet --with "ruff==${RUFF_VERSION}" ruff check . || failed+=("ruff check")
fi

echo "== shellcheck"
if [[ -z "$(find . \( -name '*.sh' -o -name '*.bash' \) -type f -not -path './.*' -print -quit)" ]]; then
  echo "No shell scripts found, so shellcheck would check nothing." >&2
  failed+=("shellcheck")
else
  find . \( -name '*.sh' -o -name '*.bash' \) -type f -not -path './.*' -print0 |
    xargs -0 -P 8 -n 16 shellcheck -s bash || failed+=("shellcheck")
fi

# .zsh files are not shellchecked, so zsh-only syntax would break the bash scripts sourcing it
# without any other check noticing
echo "== zsh utils parse as bash"
bash -n tools/zsh/utils.zsh || failed+=("zsh utils parse as bash")

echo "== skills"
uv run tools/agents/check-skills.py || failed+=("skills")

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '\n❌ Linting failed: %s\n' "${failed[*]}" >&2
  exit 1
fi
