source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

if have lazydocker; then
  alias d="lazydocker"
fi

if have docker; then
  # Docker
  da() { docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"; }  # list all containers
  db() { docker build . "$@"; }
  de() { docker container exec -it "$@" sh; }
  dp() { docker system prune "$@"; }

  # Docker Compose
  dc() { docker compose "$@"; }
  dd() { dc down "$@" }   # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
  dl() { dc logs --follow --tail=100; }                          # see last 100 log lines of one or more services (or all services if no args provided)
  du() { dc up --build --detach --remove-orphans; }              # recreate and start one or more services (or all services if no args provided)
fi

