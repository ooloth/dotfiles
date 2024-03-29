export DEBUG=false

export EDITOR=code

# see: https://github.com/eza-community/eza/blob/main/man/eza.1.md#environment-variables
# see: https://github.com/eza-community/eza/blob/main/src/options/vars.rs
export EZA_GRID_ROWS=10
export EZA_ICON_SPACING=2
export EZA_STRICT=true
export TIME_STYLE='long-iso'

export GOKU_EDN_CONFIG_FILE=$HOME/.config/karabiner/karabiner.edn

# TODO: customize HISTORY behavior (validate ideas below + use with fzf?)
export HISTSIZE=10000
SAVEHIST=10000
export HISTCONTROL=ignoreboth:erasedups
export HISTORY_IGNORE="git*"
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
# alias history='history 0'
# alias h='history | grep'

# see: https://github.com/Homebrew/homebrew-bundle#versions-and-lockfiles
export HOMEBREW_BUNDLE_NO_LOCK=1

export IS_WORK_LAPTOP=$( [[ -d "$HOME/Repos/recursionpharma" ]] && echo "true" || echo "false" )

export K9SCONFIG=$HOME/.config/k9s

export PATH=/usr/local/bin:$PATH # Add Homebrew's executable directory to front of PATH

# pyenv
# NOTE: do NOT use eval "$(pyenv init -)" or eval "$(pyenv virtualenv-init -)" (they slow the shell down a lot)
# see: https://github.com/pyenv/pyenv?tab=readme-ov-file#set-up-your-shell-environment-for-pyenv
export PYENV_ROOT=$HOME/.pyenv
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

# python
# see: https://github.com/recursionpharma/data-science-onboarding#cloning-some-internal-repos
export PYTHONPATH=$HOME
export MYPYPATH=$HOME
# Use starship prompt for virtualenv prompt placement (see: https://stackoverflow.com/a/72715907/8802485)
export VIRTUAL_ENV_PROMPT=''

export SHELL=$(which zsh)

export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

# enable vi mode
bindkey -v
# restore history search while in vi mode
# bindkey ^R history-incremental-search-backward
# bindkey ^S history-incremental-search-forward

# see: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#user-config
export XDG_CONFIG_HOME=$HOME/.config
