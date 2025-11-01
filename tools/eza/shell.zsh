source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

# see: https://github.com/eza-community/eza/blob/main/man/eza.1.md#environment-variables
# see: https://github.com/eza-community/eza/blob/main/src/options/vars.rs
export EZA_GRID_ROWS=10
export EZA_ICON_SPACING=2
export EZA_STRICT=true
export TIME_STYLE=long-iso

###########
# ALIASES #
###########

# See: https://github.com/eza-community/eza#command-line-options
alias ls="eza --all --group-directories-first --classify" # top level dir + files
alias ld="ls --long --no-user --header"                   # top level details
alias lt="ls --tree --git-ignore -I .git"                 # file tree (all levels)
alias lt2="lt --level=2"                                  # file tree (2 levels only)
alias lt3="lt --level=3"                                  # file tree (3 levels only)
alias lt4="lt --level=4"                                  # file tree (4 levels only)

