#!/usr/bin/env bash
set -euo pipefail

info "🐍 Installing uv"

# See: https://docs.astral.sh/uv/getting-started/installation/
curl -LsSf https://astral.sh/uv/install.sh | sh

debug "🚀 uv is installed"
