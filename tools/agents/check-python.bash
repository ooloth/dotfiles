#!/usr/bin/env bash
# Lint, format-check and type-check every Python file under tools/agents/, the way CI does.
#
# Run with: bash tools/agents/check-python.bash [path]
#
# The path defaults to tools/agents. Rules and line length come from tools/agents/ruff.toml, and
# both tool versions are pinned below, so a local run checks what CI checks.
#
# ruff and ty both exit 0 when they find no Python files, printing only a warning, so this fails
# first if the path holds none. Otherwise a moved or emptied directory would pass every check.
#
# ty runs from a real virtualenv under .cache/ rather than through `uv run --with`, because uv
# links --with packages into its environment from elsewhere and ty does not follow that link: it
# reports pytest and yaml as unresolved imports.
set -euo pipefail

RUFF_VERSION="0.16.10"
TY_VERSION="0.0.85"

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
target="${1:-$DOTFILES/tools/agents}"

if [[ -z "$(find "$target" -name '*.py' -not -path '*/__pycache__/*' -print -quit)" ]]; then
	echo "No Python files under $target, so nothing would be checked. Pass a path that has some." >&2
	exit 1
fi

echo "== ruff check"
uv run --quiet --with "ruff==$RUFF_VERSION" ruff check "$target"

echo "== ruff format --check"
uv run --quiet --with "ruff==$RUFF_VERSION" ruff format --check "$target"

echo "== ty check"
env_dir="$DOTFILES/.cache/check-python-env"
uv venv --quiet --allow-existing "$env_dir"
uv pip install --quiet --python "$env_dir" "ty==$TY_VERSION" pytest pyyaml
"$env_dir/bin/ty" check --python "$env_dir" --python-version 3.11 "$target"
