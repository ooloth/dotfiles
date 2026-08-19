
########################
# ENVIRONMENT VARIABLES #
########################

###########
# ALIASES #
###########

alias nvm="fnm"

###############
# COMPLETIONS #
###############

# See: https://github.com/Schniz/fnm/blob/master/docs/configuration.md
#
# --corepack-enabled is intentionally omitted: it makes every `fnm install`/`use`/`default`
# call try to run `corepack enable` immediately, which fails outright for any Node version
# that doesn't already have Corepack present (all versions ≥25, plus older versions where
# npm's global upgrades have pruned it — see tools/node/install.bash). Corepack is installed
# and enabled explicitly there instead, after Node is in place.
if have fnm; then
  eval "$(fnm env --use-on-cd --shell zsh --log-level=error)"
fi

