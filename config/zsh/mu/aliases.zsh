alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

function banner() {
  # Capture the text and color arguments
  local text="$1"
  local color="$2"

  # Define the text and border styles
  local text_color="${TEXT_BRIGHT}$color"
  local border_color="${TEXT_NORMAL}$color"
  local border_char="="
  local border_char_top_left_corner="╔"
  local border_char_top_right_corner="╗"
  local border_char_bottom_right_corner="╝"
  local border_char_bottom_left_corner="╚"
  local border_char_horizontal="═"
  local border_char_vertical="║"

  # Calculate the width of the text, adding one extra column per emoji (since they generally occupy two columns onscreen)
  local char_count=${#text}
  local emoji_count=$(echo -n "$text" | python3 -c "import sys, unicodedata; print(sum((unicodedata.category(ch) == 'So') for ch in sys.stdin.read()))")
  local padding_left=1
  local padding_right=1
  local text_cols=$((padding_left + char_count + emoji_count + padding_right))

  # Build the banner components
  local border_top="$border_color$border_char_top_left_corner$(repeat $text_cols; printf $border_char_horizontal)$border_char_top_right_corner"
  local border_vertical="$border_color$border_char_vertical"
  local border_bottom="$border_color$border_char_bottom_left_corner$(repeat $text_cols; printf $border_char_horizontal)$border_char_bottom_right_corner"
  local text="$text_color $text "

  # Output the assembled banner
  printf "\n$border_top\n$border_vertical$text$border_vertical\n$border_bottom\n\n"
}

function info() {
  local text="$1"
  local color="${TEXT_WHITE}"
  banner $text $color
}

function warn() {
  local text="$1"
  local color="${TEXT_YELLOW}"
  banner $text $color
}

function error() {
  local text="$1"
  local color="${TEXT_RED}"
  banner $text $color
}

alias c='clear'
alias cat='bat --paging=never'
alias cte='EDITOR=vim crontab -e'
alias ctl='crontab -l'
alias con='cd $HOME/Repos/ooloth/content'
alias dot='cd $HOME/Repos/ooloth/dotfiles'

alias d='lazydocker'

alias da='docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dash='cd $HOME/Repos/ooloth/dashboard'
de() { docker container exec -it $1 sh; }

# TODO: improve defaults
dc() { docker compose "$@"; }
alias dd='dc down --remove-orphans'                # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
alias dl='dc logs --follow --tail=100'             # see last 100 log lines of one or more services (or all services if no args provided)
alias du='dc up --build --detach --remove-orphans' # recreate and start one or more services (or all services if no args provided)
alias dud='dc up --detach'                         # start one or more services (or all services if no args provided)

diff() { kitten diff "$1" "$2"; } # see: https://sw.kovidgoyal.net/kitty/kittens/diff/
alias env='env | sort'
alias f='vifm'
alias g='lazygit'
alias h='cd $HOME'
image() { kitten icat "$1"; } # see: https://sw.kovidgoyal.net/kitty/kittens/icat/

# Kubernetes
alias k='kubectl'
alias kc='k create'
alias kcd='k create deployment'
alias kd='k describe'
alias ke='k expose'
alias kg='k get'
alias kgw='kg -o wide'
alias kgy='kg -o yaml'
alias ka='kg all'
alias kr='k run'
alias ks='k scale'
# Use stern as a replacement for kubectl logs
# Tails a pod regex or "resource/name" and shows logs for any containers that match the regex
# Add -c regex to filter by container name
# see: https://github.com/stern/stern#usage
alias kl='stern'

# kill process running on given port
kill() { lsof -t -i:$1 | xargs kill -9; }

# see: https://github.com/eza-community/eza#command-line-options
# see EZA_* env vars in zsh/mu/variables.zsh
alias ls='eza --all --group-directories-first --classify' # top level dir + files
alias ld='ls --long --no-user --header --grid'            # top level details
alias lt='ls --tree --git-ignore -I .git'                 # file tree (all levels)
alias lt2='lt --level=2'                                  # file tree (2 levels only)
alias lt3='lt --level=3'                                  # file tree (3 levels only)
alias lt4='lt --level=4'                                  # file tree (4 levels only)
alias md='cd $HOME/Repos/ooloth/media'
alias mr='sudo shutdown -r now' # restart macos
alias mini="s michael@mini.local"                         # automatically log in using SSH key pair
alias mu='cd $HOME/Repos/ooloth/michaeluloth.com'

n() { npm install -- $1; }
nb() { n && npm run build; }
nc() { npm run check; }
nd() { n && npm run dev; }
nfc() { npm run format:check; }
nff() { npm run format:fix; }
ng() {
  # prefer "-g" over "--location=global" to support older versions of npm
  npm install -g \
    @githubnext/github-copilot-cli \
    npm-check

  # neovim dependencies
  npm install -g \
    typescript \
    vscode-langservers-extracted
}
nk() { npm run types:check; }
nlc() { npm run lint:check; }
nlf() { npm run lint:fix; }
ns() { n && npm run start; }
nu() { n && npm-check -u; }

alias nvm='fnm'
alias oo='cd $HOME/Repos/ooloth'
alias pilots='cd $HOME/Repos/ooloth/download-pilots'
pi() { eval "$(pyenv init -)"; }
alias rm='trash' # see: https://github.com/sindresorhus/trash-cli
alias R="exec -l $SHELL"
alias rg="rg --hyperlink-format=kitty" # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
alias s="kitten ssh" # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
alias scraper='cd $HOME/Repos/ooloth/scraper'

# -s: symbolic - create a symbolic link (not a hard link)
# -f: force - if the target file already exists, unlink it so the link may occur
# -v: verbose - print file names as they are processed
sl() { ln -sfv $1 $2; } # easier symlinking

alias t='tmux a'
alias transfer='kitten transfer' # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/

u() {
  info "🔗 Updating symlinks"
  $DOTFILES/bin/create-symlinks.zsh

  info "✨ Updating rust dependencies"
  rustup update

  info "✨ Updating tmux dependencies"
  # see: https://github.com/tmux-plugins/tpm/blob/master/docs/managing_plugins_via_cmd_line.md
  ~/.config/tmux/plugins/tpm/bin/clean_plugins
  ~/.config/tmux/plugins/tpm/bin/install_plugins
  ~/.config/tmux/plugins/tpm/bin/update_plugins all

  info "✨ Updating neovim dependencies"
  local vim_kitty_navigator="$HOME/Repos/knubie/vim-kitty-navigator"
  if [ ! -d $vim_kitty_navigator ]; then
    # see: https://github.com/knubie/vim-kitty-navigator?tab=readme-ov-file#kitty
    git clone knubie/vim-kitty-navigator $vim_kitty_navigator;
    sl $vim_kitty_navigator/get_layout.py $HOME/.config/kitty
    sl $vim_kitty_navigator/pass_keys.py $HOME/.config/kitty
  else
    git -C $vim_kitty_navigator pull;
  fi

  # TODO: update lazy.nvim plugins here as well? in all nvim instances? pin dependencies to avoid unwanted updates?

  # see: https://docs.npmjs.com/cli/v9/commands/npm-update?v=true#updating-globally-installed-packages
  info "✨ Updating Node $(node -v) global dependencies"
  # TODO: only if out of date (to avoid wasting time?)
	ng

  if $IS_WORK_LAPTOP; then
    info "✨ Updating gcloud components"
    # The "quiet" flag skips interactive prompts by using the default or erroring (see: https://stackoverflow.com/a/31811541/8802485)
    gcloud components update --quiet
  fi

  info "✨ Updating brew packages"
  # Install missing packages, upgrade outdated packages, and remove old versions
  # TODO: maintain separate Brewfiles for work laptop, personal laptop and Mini?
  # Ok to vary the file name?
  # If not, can I symlink the Brewfile to the appropriate one based on the $HOSTNAME?
  # Reference the appropriate one by interpolating the $HOSTNAME?
  brew bundle --file=$DOTFILES/macos/Brewfile
	brew update && brew upgrade && brew autoremove && brew cleanup && brew doctor

  # Avoid potential issues on work laptop caused by updating macOS too early
  if ! $IS_WORK_LAPTOP; then
    info "💻 Updating macOS software"
    softwareupdate --install --all --agree-to-license --verbose
  fi

  info "🔄 Reloading shell"
  R
}

alias v='NVIM_APPNAME=nvim-lazyvim nvim'
alias vim='nvim'

# find all directories two levels below ~/Repos, pass them to fzf, and open the selected one in vs code
vs() {
  code "$(fd -t d --max-depth 2 --min-depth 2 . $HOME/Repos | fzf)"
}

vv() {
  # Assumes all configs are in directories named ~/.config/nvim-*
  local config=$(fd --max-depth 1 --glob 'nvim-*' ~/.config | fzf --prompt="Neovim Config > " --height=~50% --layout=reverse --border --exit-0)

  # If I exit fzf without selecting a config, don't open Neovim
  [[ -z $config ]] && echo "No config selected" && return

  # Open Neovim with the selected config
  NVIM_APPNAME=$(basename $config) nvim $@
}

alias x='exit'

# see: https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# [z]sh [t]ime: measure how long new shells take to launch
zt() { for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done }
