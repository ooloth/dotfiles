#!/usr/bin/env zsh

local DOTFILES=$HOME/Repos/ooloth/dotfiles
local DOTCONFIG=$DOTFILES/config
local HOMECONFIG=$HOME/.config

local sl() { ln -sfv "$1" "$2"; }

mkdir -p $HOMECONFIG/alacritty
sl $DOTCONFIG/alacritty/alacritty.yml $HOMECONFIG/alacritty

mkdir -p $HOMECONFIG/gh
sl $DOTCONFIG/gh/config.yml $HOMECONFIG/gh

mkdir -p $HOMECONFIG/git
sl $DOTCONFIG/git/config $HOMECONFIG/git
sl $DOTCONFIG/git/config.work $HOMECONFIG/git
sl $DOTCONFIG/git/ignore $HOMECONFIG/git

sl $DOTFILES/.hushlogin $HOME

mkdir -p $HOMECONFIG/k9s/skins
sl $DOTCONFIG/k9s/config.yml $HOMECONFIG/k9s
sl $DOTCONFIG/k9s/skin.yml $HOMECONFIG/k9s
sl $DOTCONFIG/k9s/skins/dracula.yml $HOMECONFIG/k9s/skins

mkdir -p $HOMECONFIG/karabiner
sl $DOTCONFIG/karabiner/karabiner.edn $HOMECONFIG/karabiner

mkdir -p $HOMECONFIG/kitty/colorscheme
mkdir -p $HOMECONFIG/kitty/startup
sl $DOTCONFIG/kitty/colorscheme/catppuccin-mocha.conf $HOMECONFIG/kitty/colorscheme
sl $DOTCONFIG/kitty/colorscheme/dracula.conf $HOMECONFIG/kitty/colorscheme
sl $DOTCONFIG/kitty/colorscheme/gruvbox-dark-hard.conf $HOMECONFIG/kitty/colorscheme
sl $DOTCONFIG/kitty/colorscheme/material-ocean.conf $HOMECONFIG/kitty/colorscheme
sl $DOTCONFIG/kitty/colorscheme/nightfly.conf $HOMECONFIG/kitty/colorscheme
sl $DOTCONFIG/kitty/kitty.conf $HOMECONFIG/kitty
sl $DOTCONFIG/kitty/startup/Air.conf $HOMECONFIG/kitty/startup
sl $DOTCONFIG/kitty/startup/MULO-JQ97NW-MBP.conf $HOMECONFIG/kitty/startup
# see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/get_layout.py $HOMECONFIG/kitty
sl $HOME/Repos/knubie/vim-kitty-navigator/pass_keys.py $HOMECONFIG/kitty
# set HOSTNAME for kitty startup config swapping
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-414186903
# see: https://github.com/kovidgoyal/kitty/issues/811#issuecomment-434876639
# see: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.startup_session
sl $DOTFILES/macos/kitty.environment.plist $HOME/Library/LaunchAgents

mkdir -p $HOMECONFIG/lazydocker
sl $DOTCONFIG/lazydocker/config.yml $HOMECONFIG/lazydocker

mkdir -p $HOMECONFIG/lazygit
sl $DOTCONFIG/lazygit/config.yml $HOMECONFIG/lazygit

sl $DOTFILES/.npmrc $HOME

mkdir -p $HOMECONFIG/nvim
sl $DOTCONFIG/nvim/init.lua $HOMECONFIG/nvim
sl $DOTCONFIG/nvim-ide $HOMECONFIG
sl $DOTCONFIG/nvim-kitty-scrollback $HOMECONFIG
sl $DOTCONFIG/nvim-lazyvim $HOMECONFIG

mkdir -p $HOMECONFIG/starship
sl $DOTCONFIG/starship/config.toml $HOMECONFIG/starship

mkdir -p $HOMECONFIG/surfingkeys
sl $DOTCONFIG/surfingkeys/surfingkeys.js $HOMECONFIG/surfingkeys

mkdir -p $HOMECONFIG/tmux
sl $DOTCONFIG/tmux/battery.sh $HOMECONFIG/tmux
sl $DOTCONFIG/tmux/gitmux.conf $HOMECONFIG/tmux
sl $DOTCONFIG/tmux/tmux.conf $HOMECONFIG/tmux

mkdir -p $HOMECONFIG/vifm
sl $DOTCONFIG/vifm/colors $HOMECONFIG/vifm
sl $DOTCONFIG/vifm/mu $HOMECONFIG/vifm
sl $DOTCONFIG/vifm/vifmrc $HOMECONFIG/vifm

sl $DOTFILES/vscode/settings.json "$HOME/Library/Application Support/Code/User"
sl $DOTFILES/vscode/keybindings.json "$HOME/Library/Application Support/Code/User"
sl $DOTFILES/vscode/snippets "$HOME/Library/Application Support/Code/User"

mkdir -p $HOMECONFIG/wezterm
sl $DOTCONFIG/wezterm/wezterm.lua $HOMECONFIG/wezterm

mkdir -p $HOMECONFIG/yamllint
sl $DOTCONFIG/yamllint/config $HOMECONFIG/yamllint

mkdir -p $HOMECONFIG/yazi
sl $DOTCONFIG/yazi/flavors $HOMECONFIG/yazi
sl $DOTCONFIG/yazi/keymap.toml $HOMECONFIG/yazi
sl $DOTCONFIG/yazi/theme.toml $HOMECONFIG/yazi
sl $DOTCONFIG/yazi/yazi.toml $HOMECONFIG/yazi

sl $DOTFILES/.zshenv $HOME
sl $DOTCONFIG/zsh/.zprofile $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/.zshrc $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/aliases.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/banners.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/check.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/hooks.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/options.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/p10k.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/plugins.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/start.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/stop.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/test.zsh $HOMECONFIG/zsh
sl $DOTCONFIG/zsh/update.zsh $HOMECONFIG/zsh