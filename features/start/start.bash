#!/usr/bin/env bash
set -euo pipefail

source "${DOTFILES}/tools/bash/utils.bash"

current_dir=$(basename "${PWD}")
error_msg="🚨 No 'start' case defined for '/${current_dir}'"

if is_work; then
  case "${current_dir}" in
  react-app)
    info "🚀 Starting vite server"
    npm install
    npm start
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
else
  case "${current_dir}" in
  michaeluloth.com)
    npm run dev
    ;;

  *)
    error "${error_msg}"
    ;;
  esac
fi
