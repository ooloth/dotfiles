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
  printf "\n$border_top\n$border_vertical$text$border_vertical\n$border_bottom\n\n${TEXT_NORMAL}"
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
# alias history='history 0'
# alias h='history | grep'
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
alias ld='ls --long --no-user --header'                   # top level details
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
sl() { ln -sfv "$1" "$2"; } # easier symlinking
alias t='tmux a'
alias transfer='kitten transfer' # see: https://sw.kovidgoyal.net/kitty/kittens/transfer/
# NOTE: "u" = "update" (see update.zsh)
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
  n() { npm install "$@"; }
  nb() { n && npm run build; }
  nfc() { npm run format:check; }
  nff() { npm run format:fix; }
  nk() { npm run typecheck; }
  nl() { npm run lint; }
  nlc() { npm run lint:check; }
  nlf() { npm run lint:fix; }
  ns() { n && npm run start; }
  nt() { npm run test "$@"; }
  nu() { n && npm-check -u; }
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
      # Install debugpy to support debugging the flask app by attaching to it
      pip install debugpy
    fi
  }

  skurge() { cd $HOME/Repos/recursionpharma/skurge; }

  start() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      # NOTE: these only apply if not able to use the dev container; if I am, use it and do this instead:
      # https://github.com/recursionpharma/bc-lowe/blob/trunk/README.md#quickstart
      bc-lowe)
        # See: https://recursion.slack.com/archives/D03LJSVPQ67/p1715265297434329?thread_ts=1715264518.353969&cid=D03LJSVPQ67

        # Ensure Docker Desktop is running and Kubernetes is enabled
        info "📡 Pointing to Docker Desktop's Kubernetes instance"
        kubectl config use-context docker-desktop

        info "🚀 Starting postgres on port 5432"
        brew services stop postgresql@14
        lsof -t -i:5432 | xargs kill -9
        kubectl apply -f deploy/local/postgres.yaml
        kubectl wait --for=condition=ready pod -l app=postgres
        kubectl port-forward svc/postgres 5432:5432 & \

        info "🚀 Starting redis on port 6379"
        brew services stop redis
        lsof -t -i:6379 | xargs kill -9
        kubectl apply -f deploy/local/redis.yaml
        kubectl wait --for=condition=ready pod -l app=redis
        kubectl port-forward svc/redis 6379:6379 & \

        info "🚀 Starting backend server with bazel"
        pip_index_url=$(python3 -m pip config get global.index-url)
        PIP_INDEX_URL=$pip_index_url bazel run //src/api:manage migrate
        PIP_INDEX_URL=$pip_index_url bazel run //src/api:manage runserver

        info "🚀 Starting worker with bazel"
        PIP_INDEX_URL=$pip_index_url bazel run //src/api:worker

        # Ensure necessary NEXT_PUBLIC_* environment variables are set in .env.local
        info "🚀 Starting frontend server with pnpm"
        fnm use 20
        pnpm i
        pnpm run web:dev ;;

      cauldron)
        du ;;

      dash-phenoapp-v2)
        # TODO: automatically rerun rv if any pip packages were updated?
        info "🚀 Starting observability stack"
        du
        info "🚀 Starting flask server with debugpy"
        FLASK_APP=phenoapp.app.py \
        FLASK_DEBUG=true \
        FLASK_ENV=development \
        FLASK_RUN_PORT=8050 \
        GOOGLE_CLOUD_PROJECT=eng-infrastructure \
        PROMETHEUS_MULTIPROC_DIR=./.prom \
        PYDEVD_DISABLE_FILE_VALIDATION=true \
        python -m debugpy --listen 5678 -m flask run --no-reload ;;

      genie)
        # the genie docker compose file starts the frontend, backend and db (no need to run any separately)
        du ;;

      grey-havens)
        ./run-local.sh ;;

      # TODO: javascript-template-react)

      platelet)
        # see: https://github.com/recursionpharma/platelet/blob/trunk/docs/setup/index.md
        GOOGLE_CLOUD_PROJECT=eng-infrastructure du ;;

      platelet-ui)
        info "🚀 Starting cauldron, genie, skurge, platelet and platelet-ui"
        cauldron && dud
        genie && dud
        pl && dud
        skurge && dud
        plu && n && du ;;

      processing-witch)
        # TODO: start anything else locally? leverage docker compose?
        python -m main ;;

      react-app)
        info "🚀 Starting vite server"
        ns ;;

      skurge)
        du ;;

      tech)
        ns ;;

      *)
        error "🚨 No 'start' case defined for '/${CURRENT_DIRECTORY}' in work.zsh" ;;
    esac
  }

  stop() {
    local CURRENT_DIRECTORY=$(basename $PWD)

    case $CURRENT_DIRECTORY in
      bc-lowe)
        info "✋ Stopping postgres instance running on port 5432"
        kubectl delete -f deploy/local/postgres.yaml
        lsof -t -i:5432 | xargs kill -9

        info "✋ Stopping redis instance running on port 6379"
        kubectl delete -f deploy/local/redis.yaml
        lsof -t -i:6379 | xargs kill -9 ;;

      cauldron)
        info "✋ Stopping cauldron"
        dd ;;

      dash-phenoapp-v2)
        info "✋ Stopping observability stack"
        dd ;;

      genie)
        info "✋ Stopping genie"
        dd ;;

      platelet-ui)
        info "✋ Stopping cauldron, genie, skurge, platelet and platelet-ui"
        cauldron && dd
        genie && dd
        pl && dd
        skurge && dd
        plu && dd ;;

      skurge)
        dd ;;

      *)
        error "🚨 No 'stop' case defined for '/${CURRENT_DIRECTORY}' in work.zsh\n" ;;
    esac
  }

  tech() { cd $HOME/Repos/recursionpharma/tech; }
  zuul() { cd $HOME/Repos/recursionpharma/zuul; }

  # TODO: test() {}
  # TODO: format() {}
  # TODO: lint() {}
  # TODO: typecheck() {}
fi
