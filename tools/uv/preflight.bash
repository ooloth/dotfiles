#!/usr/bin/env bash
set -uo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

# On the work laptop, uv installs through the work Artifact Registry index in ~/.config/uv/uv.toml,
# which needs gcloud's application-default credentials. `uv tool install --upgrade` in harlequin,
# neovim, ty and visidata fails with a 403 without them.
if ! is_work; then
  exit 0
fi

if ! gcloud auth application-default print-access-token &>/dev/null; then
  echo "uv installs tools through the work Artifact Registry, and gcloud's application-default credentials have expired. Refresh them: gca" >&2
  exit 1
fi
