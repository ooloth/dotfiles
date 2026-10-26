########################
# ENVIRONMENT VARIABLES #
########################

# `brew shellenv` (which sets PATH, FPATH, MANPATH, INFOPATH) runs in tools/zsh/config/core.zsh,
# before the tools/ sourcing loop runs. It must run before tool-specific PATH prepends (e.g. fnm's
# shim), because it puts /opt/homebrew/bin at the front of PATH and would shadow them.
export HOMEBREW_NO_AUTO_UPDATE=1      # I'll update manually (don't slow down individual install/upgrade commands)
export HOMEBREW_NO_INSTALL_CLEANUP=1  # I'll clean up manually (don't slow down individual install/upgrade commands)
export HOMEBREW_NO_ASK=1              # Don't ask for confirmation before upgrading (so `u` can run unattended)

# The work laptop's IT updates some apps as root, which brew can't replace without admin rights.
# Even without greedy, brew upgrades an auto_updates cask once the app falls behind the tap, so
# work also turns that off and leaves those apps to IT and their own updaters.
# Unset rather than skip, because tmux passes the variables on to new shells.
if is_work; then
  unset HOMEBREW_UPGRADE_GREEDY
  export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
else
  export HOMEBREW_UPGRADE_GREEDY=1    # Upgrade casks with auto-updates: true or version: latest as well
  unset HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS
fi

###########
# ALIASES #
###########

