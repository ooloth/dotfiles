#!/usr/bin/env bash
# Type-checks every file a type checker covers.
#
# Run with: bash scripts/checks/types.bash
#
# Python: ty, with settings from ty.toml at the root. ty runs with --project rather than
# --config-file, which would resolve the archive exclude against the working directory. ty exits 0
# when it finds no Python files, so this fails first if there are none.
#
# ty runs from a real virtualenv under .cache/ rather than through `uv run --with`, because uv
# links --with packages into its environment from elsewhere and ty does not follow that link: it
# reports pytest and yaml as unresolved imports.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${DOTFILES}/scripts/checks/versions.bash"

if [[ -z "$(find "${DOTFILES}" -name '*.py' -not -path '*/__pycache__/*' -print -quit)" ]]; then
  echo "No Python files found, so nothing would be checked." >&2
  exit 1
fi

echo "== ty check"
env_dir="${DOTFILES}/.cache/check-types-env"
uv venv --quiet --allow-existing "${env_dir}"
uv pip install --quiet --python "${env_dir}" "ty==${TY_VERSION}" pytest pyyaml hypothesis
"${env_dir}/bin/ty" check --python "${env_dir}" --project "${DOTFILES}" "${DOTFILES}"
