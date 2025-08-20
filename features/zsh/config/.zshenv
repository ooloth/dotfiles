# Prevent zsh from sourcing /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout (and only source my own zsh init files)
# See: https://unix.stackexchange.com/questions/72559/how-to-avoid-parsing-etc-files
unsetopt GLOBAL_RCS

export ZDOTDIR=$HOME/.config/zsh
