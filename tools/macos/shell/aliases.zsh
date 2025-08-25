#!/usr/bin/env zsh

source "${DOTFILES}/tools/macos/shell/variables.zsh"

is_air() { [[ "$COMPUTER" == "air" ]]; }
is_mini() { [[ "$COMPUTER" == "mini" ]]; }
is_work() { [[ "$COMPUTER" == "work" ]]; }
