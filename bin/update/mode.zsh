#!/usr/bin/env zsh

source "${DOTFILES}/zsh/config/utils.zsh"

main() {
  info "🔋 Updating executable permissions"

  # Make all ".bash" and ".sh" and ".zsh" files in $DOTFILES/bin executable
  fd . "${DOTFILES}/bin" --type f -e bash -e sh -e zsh -X chmod +x

  # Make all files with no extension (inferred from no "." in name) in $DOTFILES/bin executable
  fd --type f --regex '^[^.]+$' "${DOTFILES}/bin" -X chmod +x

  printf "🚀 All scripts are executable\n"
}

main "$@"
