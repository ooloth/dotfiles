# PATH configuration (defined separately so it can be sourced by .zprofile)

# Deno
if $IS_AIR; then
  export PATH="/opt/homebrew/bin/deno:$PATH"
fi

# Go
export PATH="$HOME/go/bin:$PATH"

# OpenSSL
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

# Pyenv
# NOTE: do NOT use eval "$(pyenv init -)" or eval "$(pyenv virtualenv-init -)" (they slow the shell down a lot)
# see: https://github.com/pyenv/pyenv?tab=readme-ov-file#set-up-your-shell-environment-for-pyenv
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

# Rust
export PATH="$HOME/.config/cargo/bin:$PATH"

# Homebrew (keep last so will be at front of PATH)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:$PATH" # Add Homebrew's executable directory to front of PATH

export IS_WORK=$( [[ "$(hostname)" == "MULO-JQ97NW-MBP" ]] && echo "true" || echo "false" )

if $IS_WORK; then
  # TODO: port work/zprofile.zsh to work/variables.zsh and work/path.zsh
  source "$DOTFILES/config/zsh/work/path.zsh"
fi
