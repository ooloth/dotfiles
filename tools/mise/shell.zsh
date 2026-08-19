
########################
# ENVIRONMENT VARIABLES #
########################

###########
# ALIASES #
###########

###############
# COMPLETIONS #
###############

# Not auto-activated: no project on this laptop uses mise for version-switching (only a global
# Ruby pin in ~/.config/mise/config.toml). `mise activate zsh` caches PATH in __MISE_ORIG_PATH the
# first time it runs per shell and never refreshes it, so a stale copy silently overrides whatever
# other tools (e.g. fnm) put on PATH afterward, on every prompt, for the life of the shell/tmux
# session. If per-project version-switching is ever needed again, re-add:
#   if have mise; then
#     eval "$(mise activate zsh)"
#   fi
# and unset __MISE_ORIG_PATH right before it, so it can't inherit a stale baseline from an old shell.

