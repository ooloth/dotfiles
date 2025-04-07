# This file is sourced first. Setting PATH here ensures that it will apply to all zsh scripts, login shells, and interactive shells.
# See: https://news.ycombinator.com/item?id=39508793
# See: https://zsh.sourceforge.io/Doc/Release/Files.html
source "$HOME/Repos/ooloth/dotfiles/config/zsh/path.zsh"

# Prevent zsh from sourcing /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout (and only source my own zsh init files)
# See: https://unix.stackexchange.com/questions/72559/how-to-avoid-parsing-etc-files
unsetopt GLOBAL_RCS

# Device
export HOSTNAME=$(networksetup -getcomputername)

# When referenced in "if" statements, will execute the true/false unix commands that return 0 or 1
# When read directly, will contain "true" or "false" strings
export IS_AIR=false
export IS_MINI=false
export IS_WORK=false

[[ "$HOSTNAME" == "Air" ]] && IS_AIR=true
[[ "$HOSTNAME" == "Mini" ]] && IS_MINI=true
[[ "$HOSTNAME" == "7385-Y3FH97X-MAC" || "$HOSTNAME" == "MULO-JQ97NW-MBP" ]] && IS_WORK=true

export ZDOTDIR=$HOME/.config/zsh
