export EDITOR='nvim'
export GOKU_EDN_CONFIG_FILE=$HOME/.config/karabiner/karabiner.edn

export PATH=/usr/local/bin:$PATH # Add Homebrew's executable directory to front of PATH
export PATH=$HOME/.local/bin:$PATH # Add lvim location to PATH
export PATH=$HOME/.cargo/bin:$PATH # Add cargo to PATH (for lvim)

export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

IS_WORK_LAPTOP=false
if [[ -d "$HOME/Repos/recursionpharma" ]]; then IS_WORK_LAPTOP=true; fi

