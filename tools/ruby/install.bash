#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

info "💎 Installing Ruby"
# See: https://guides.rubyonrails.org/install_ruby_on_rails.html#install-ruby-on-macos
mise use -g ruby@3
