
if ! have docker; then
  return 0
fi

########################
# ENVIRONMENT VARIABLES #
########################

###########
# ALIASES #
###########

# Docker
da() { docker container ls --all --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"; }  # list all containers
de() { docker container exec -it "$@" sh; }
# Both ask before deleting and leave volumes, which hold local databases. Docker's `until` filter
# leaves anything made more recently, such as another session's stopped containers and its cache;
# running containers are never pruned. `u` says when either is worth running.
dp() { docker system df; docker system prune --filter until=168h; docker system df; }         # stopped containers, unused networks, dangling images and build cache, older than a week
dpa() { docker system df; docker system prune --all --filter until=720h; docker system df; }  # the same kinds plus every unused image and all unused build cache, but only what is older than 30 days

if is_work; then
  alias db="docker build --secret id=gcp_adc,src=${HOME}/.config/gcloud/application_default_credentials.json ."
else
  alias db="docker build ."
fi

# Docker Compose. No shortcut is named du, dd or dc, so those stay the system's disk usage, copy and calculator
dcc() { docker compose "$@"; }
dcd() { dcc down "$@"; }                                  # stop and remove one or more services' containers and networks (or all if no args provided); volumes stay
dl() { dcc logs --follow --tail=100 "$@"; }               # see last 100 log lines of one or more services (or all services if no args provided)
dcu() { dcc up --build --detach --remove-orphans "$@"; }  # recreate and start one or more services (or all services if no args provided)

###############
# COMPLETIONS #
###############

cached_completion docker docker completion zsh

