#!/usr/bin/env zsh

################
# Dependencies #
################

DOTFILES="$HOME/Repos/ooloth/dotfiles"
DOTCONFIG="$DOTFILES/config"
HOMECONFIG="$HOME/.config"

source "$DOTCONFIG/zsh/aliases.zsh"
source "$DOTCONFIG/zsh/utils.zsh"

maybe_symlink() {
  # Both arguments should be absolute paths
  local source_file="$1"
  local target_dir="$2"

  local file_name="$(basename "$source_file")"
  local target_path="$target_dir/$file_name"

  # Check if the target file exists and is a symlink pointing to the correct source file
  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_file" ]; then
    return 0
  fi

  mkdir -p "$target_dir"
  printf "🔗 " # inline prefix for the output of the next line
  ln -sfv "$source_file" "$target_dir"
}

# TODO: start by removing broken symlinks in each target directory?

info "🔗 Updating symlinks"

#############
# Target: ~ #
#############

maybe_symlink "$DOTFILES/claude/config/agents" "$HOME/.claude"
maybe_symlink "$DOTFILES/claude/config/CLAUDE.md" "$HOME/.claude"
maybe_symlink "$DOTFILES/claude/config/commands" "$HOME/.claude"
maybe_symlink "$DOTFILES/claude/config/settings.json" "$HOME/.claude"
maybe_symlink "$DOTFILES/zsh/config/.hushlogin" "$HOME"
maybe_symlink "$DOTFILES/zsh/config/.zshenv" "$HOME"

#####################
# Target: ~/.config #
#####################

# Find all files at any level under $DOTCONFIG (see: https://github.com/sharkdp/fd)
fd --type file --hidden . "$DOTCONFIG" | while read file; do
  local relpath="${file#$DOTCONFIG/}"    # Get the relative path in that follows "$DOTCONFIG/" in $file (which is an absolute path)
  local dirpath="$(dirname "$relpath")"  # Get the directory path by dropping the file name
  local targetdir="$HOMECONFIG/$dirpath" # Build the absolute path to the target directory

  maybe_symlink "$file" "$targetdir" # Symlink the file to the target directory
done

# TODO: recursively symlink any file in [tool}/config (but not /config itself)?
# Or just source {tool}/symlink.bash files that each define their own commands?
maybe_symlink "$DOTFILES/gh/config/config.yml" "$HOMECONFIG/gh"
maybe_symlink "$DOTFILES/ghostty/config/config" "$HOMECONFIG/ghostty"
maybe_symlink "$DOTFILES/git/config/config" "$HOMECONFIG/git"
maybe_symlink "$DOTFILES/git/config/config.work" "$HOMECONFIG/git"
maybe_symlink "$DOTFILES/k9s/config/aliases.yaml" "$HOMECONFIG/k9s"
maybe_symlink "$DOTFILES/k9s/config/clusters" "$HOMECONFIG/k9s"
maybe_symlink "$DOTFILES/k9s/config/config.yaml" "$HOMECONFIG/k9s"
maybe_symlink "$DOTFILES/k9s/config/hotkeys.yaml" "$HOMECONFIG/k9s"
maybe_symlink "$DOTFILES/k9s/config/skins" "$HOMECONFIG/k9s"
maybe_symlink "$DOTFILES/kitty/config/colorscheme" "$HOMECONFIG/kitty"
maybe_symlink "$DOTFILES/kitty/config/kitty.conf" "$HOMECONFIG/kitty"
maybe_symlink "$DOTFILES/lazydocker/config/config.yml" "$HOMECONFIG/lazydocker"

yazi_flavors="$HOME/Repos/yazi-rs/flavors"

if [ ! -d "$yazi_flavors" ]; then
  source "$DOTFILES/bin/install/yazi.zsh"
else
  # see: https://github.com/yazi-rs/flavors/tree/main/catppuccin-mocha.yazi
  maybe_symlink "$yazi_flavors/catppuccin-mocha.yazi" "$HOMECONFIG/yazi/flavors"
fi

#####################
# Target: ~/Library #
#####################

VSCODEUSER="$HOME/Library/Application Support/Code/User"

maybe_symlink "$DOTFILES/vscode/config/keybindings.json" "$VSCODEUSER"
maybe_symlink "$DOTFILES/vscode/config/settings.json" "$VSCODEUSER"
maybe_symlink "$DOTFILES/vscode/config/snippets" "$VSCODEUSER"

printf "🎉 All symlinks are up to date\n"
