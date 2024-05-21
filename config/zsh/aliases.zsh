alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
# NOTE: "banner" defined in banners.zsh
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
dc() { docker compose "$@"; }
alias dd='dc down --remove-orphans'                # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
alias dl='dc logs --follow --tail=100'             # see last 100 log lines of one or more services (or all services if no args provided)
alias du='dc up --build --detach --remove-orphans' # recreate and start one or more services (or all services if no args provided)
alias dud='dc up --detach'                         # start one or more services (or all services if no args provided)
diff() { kitten diff "$1" "$2"; } # see: https://sw.kovidgoyal.net/kitty/kittens/diff/
alias env='env | sort'
# NOTE: "error" defined in banners.zsh
alias f='vifm'
alias g='lazygit'
alias h='cd $HOME'
# alias history='history 0'
# alias h='history | grep'
image() { kitten icat "$1"; } # see: https://sw.kovidgoyal.net/kitty/kittens/icat/
# NOTE: "info" defined in banners.zsh
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
# NOTE: see EZA_* env vars in .zshenv
alias ls='eza --all --group-directories-first --classify' # top level dir + files
alias ld='ls --long --no-user --header'                   # top level details
alias lt='ls --tree --git-ignore -I .git'                 # file tree (all levels)
alias lt2='lt --level=2'                                  # file tree (2 levels only)
alias lt3='lt --level=3'                                  # file tree (3 levels only)
alias lt4='lt --level=4'                                  # file tree (4 levels only)
alias md='cd $HOME/Repos/ooloth/media'
alias mr='sudo shutdown -r now' # restart macos
alias mini="s michael@mini.local"                         # automatically log in using SSH key pair
alias mu='cd $HOME/Repos/ooloth/michaeluloth.com'
n() { npm install "$@"; }
nb() { n && npm run build; }
nc() { npm run check; }
nd() { n && npm run dev; }
nfc() { npm run format:check; }
nff() { npm run format:fix; }
ng() {
  packages=(
    aocrunner
    bash-language-server # for neovim
    cssmodules-language-server # for neovim
    dockerfile-language-server-nodejs # for neovim
    emmet-ls # for neovim
    neovim # for neovim
    npm
    npm-check
    pug-lint # for neovim
    svelte-language-server # for neovim
    tree-sitter-cli # for neovim
    typescript # for neovim
    vscode-langservers-extracted # for neovim
  )

  installed_packages=$(npm list -g --depth=0)
  outdated_packages=$(npm outdated -g)

  is_package_installed() {
    local package="$1"
    echo "$installed_packages" | grep -q " ${package}@"
  }

  is_package_outdated() {
    local package="$1"
    echo "$outdated_packages" | grep -q "^${package}"
  }

  packages_to_add=()
  packages_to_update=()

  for package in "${packages[@]}"; do
      if ! is_package_installed "$package"; then
        packages_to_add+=("$package")
      elif is_package_outdated "$package"; then
        packages_to_update+=("$package")
      fi
  done

  echo
  for package in "${packages_to_add[@]}"; do
    printf "📦 Installing %s\n" "$package"
  done

  for package in "${packages_to_update[@]}"; do
    printf "🚀 Updating %s\n" "$package"
  done

  # prefer "-g" over "--location=global" to support older versions of npm
  npm install -g --loglevel=error "${packages_to_add[@]}" "${packages_to_update[@]}"
}
nk() { npm run types:check; }
nl() { npm run lint; }
nlc() { npm run lint:check; }
nlf() { npm run lint:fix; }
ns() { n && npm run start; }
nt() { npm run test "$@"; }
nu() { n && npm-check -u; }
alias nvm='fnm'
alias oo='cd $HOME/Repos/ooloth'
pi() { eval "$(pyenv init -)"; }
alias pilots='cd $HOME/Repos/ooloth/download-pilots'
alias R="exec -l $SHELL"
alias rg="rg --hyperlink-format=kitty" # see: https://sw.kovidgoyal.net/kitty/kittens/hyperlinked_grep/
alias rm='trash' # see: https://github.com/sindresorhus/trash-cli
alias s="kitten ssh" # see: https://sw.kovidgoyal.net/kitty/kittens/ssh/
alias scraper='cd $HOME/Repos/ooloth/scraper'
sl() { ln -sfv "$1" "$2"; } # easier symlinking
symlinks() { $DOTFILES/bin/create-symlinks.zsh; }
alias t='tmux a'
alias transfer='kitten transfer' # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/
# NOTE: "u" = "update" (see update.zsh)
alias v='NVIM_APPNAME=nvim-lazyvim nvim'
alias vim='nvim'
# Find all directories two levels below ~/Repos, pass them to fzf, and open the selected one in VS Code
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
# NOTE: "warn" defined in banners.zsh
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

if $IS_WORK_LAPTOP; then
  bp() { cd $HOME/Repos/recursionpharma/build-pipelines; }
  cauldron() { cd $HOME/Repos/recursionpharma/cauldron; }
  eo() { cd $HOME/Repos/recursionpharma/eng-onboarding; }
  # see: https://stackoverflow.com/a/51563857/8802485
  # see: https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials
  gca() { gcloud auth login; }
  gcaa() { gcloud auth application-default login; }
  gci() { gcloud init; }
  gcpe() { gcloud config set project eng-infrastructure; }
  gcpn() { gcloud config set project rp006-prod-49a893d8; }
  genie() { cd $HOME/Repos/recursionpharma/genie }
  gu() { cd $HOME/Repos/recursionpharma/genie/genie-ui; }
  lowe() { cd $HOME/Repos/recursionpharma/bc-lowe; }
  mp() { cd $HOME/Repos/recursionpharma/mapapp-public; }
  pa() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2; }
  pab() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/phenoapp; }
  paf() { cd $HOME/Repos/recursionpharma/dash-phenoapp-v2/react-app; }
  pm() { cd $HOME/Repos/recursionpharma/phenomap; }
  pr() { cd $HOME/Repos/recursionpharma/phenoreader; }
  psa() { cd $HOME/Repos/recursionpharma/phenoservice-api; }
  psc() { cd $HOME/Repos/recursionpharma/phenoservice-consumer; }
  pl() { cd $HOME/Repos/recursionpharma/platelet; }
  plu() { cd $HOME/Repos/recursionpharma/platelet-ui; }
  pw() { cd $HOME/Repos/recursionpharma/processing-witch; }
  r() { cd $HOME/Repos/recursionpharma; }
  rl() { roadie lock "$@"; } # optionally "rl -c" etc
  rlc() { rl -c; }
  ru() { python -m pip install -U roadie; } # see: https://pip.pypa.io/en/stable/cli/pip_install/#options
  rv() {
    # Install latest version of roadie, then rebuild venv to remove any no-longer-used packages
    # https://github.com/recursionpharma/roadie/blob/5a5c6ba44c345c8fd42543db5454b502a4e96863/roadie/cli/virtual.py#L454
    ru && roadie venv --clobber

    local CURRENT_DIRECTORY=$(basename $PWD)

    if [[ "$CURRENT_DIRECTORY" == "dash-phenoapp-v2" ]]; then
      # TODO: remove this after installing debugpy
      # Install debugpy to support debugging the flask app by attaching to it
      pip install debugpy
    fi
  }
  skurge() { cd $HOME/Repos/recursionpharma/skurge; }
  tech() { cd $HOME/Repos/recursionpharma/tech; }
  zuul() { cd $HOME/Repos/recursionpharma/zuul; }
fi
