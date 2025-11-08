source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

if ! have docker; then
  return 0
fi

########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

# Docker
da() { docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"; }  # list all containers
de() { docker container exec -it "$@" sh; }
dp() { docker system prune; }  # remove all stopped containers, unused networks, dangling images, and build cache

if is_work; then
  alias db="docker build --secret id=gcp_adc,src=${HOME}/.config/gcloud/application_default_credentials.json ."
else
  alias db="docker build ."
fi

# Docker Compose
dc() { docker compose "$@"; }
dd() { dc down "$@" }   # stop and remove one or more containers, networks, images, and volumes (or all if no args provided)
dl() { dc logs --follow --tail=100; }                          # see last 100 log lines of one or more services (or all services if no args provided)
du() { dc up --build --detach --remove-orphans "$@"; }              # recreate and start one or more services (or all services if no args provided)

###############
# COMPLETIONS #
###############

fpath+="~/.docker/completions"

