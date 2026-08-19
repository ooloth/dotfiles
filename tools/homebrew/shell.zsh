########################
# ENVIRONMENT VARIABLES #
########################

# `brew shellenv` (which sets PATH, FPATH, MANPATH, INFOPATH) runs in tools/zsh/config/core.zsh,
# before the tools/ sourcing loop runs. It must run before tool-specific PATH prepends (e.g. fnm's
# shim) or its underlying `path_helper -s` call will hoist /opt/homebrew/bin back to the front of
# PATH and shadow them.
export HOMEBREW_NO_AUTO_UPDATE=1      # I'll update manually (don't slow down individual install/upgrade commands)
export HOMEBREW_NO_INSTALL_CLEANUP=1  # I'll clean up manually (don't slow down individual install/upgrade commands)
export HOMEBREW_UPGRADE_GREEDY=1      # Upgrade casks with auto-updates: true or version: latest as well

###########
# ALIASES #
###########

