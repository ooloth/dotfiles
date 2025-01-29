# This file is sourced first. Setting PATH here ensures that it will apply to all zsh scripts, login shells, and interactive shells.
# See: https://news.ycombinator.com/item?id=39508793
# See: https://zsh.sourceforge.io/Doc/Release/Files.html
source "$HOME/.config/zsh/path.zsh"

# Prevent zsh from sourcing /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout (and only source my own zsh init files)
# See: https://unix.stackexchange.com/questions/72559/how-to-avoid-parsing-etc-files
unsetopt GLOBAL_RCS

# Device
export HOSTNAME=$(networksetup -getcomputername)
export IS_AIR="$( [[ "$HOSTNAME" == "Air" ]] && echo "true" || echo "false" )"
export IS_MINI="$( [[ "$HOSTNAME" == "Mini" ]] && echo "true" || echo "false" )"
export IS_WORK="$( [[ "$HOSTNAME" == "7385-Y3FH97X-MAC" ]] && echo "true" || echo "false" )"
# export IS_WORK="$( [[ "$HOSTNAME" == "MULO-JQ97NW-MBP" ]] && echo "true" || echo "false" )"

export ZDOTDIR=$HOME/.config/zsh
