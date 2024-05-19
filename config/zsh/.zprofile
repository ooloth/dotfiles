# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

if $IS_WORK_LAPTOP; then
  # Netskope
  # see: https://github.com/recursionpharma/netskope_dev_tools
  source "$HOME/.config/netskope/env.sh"

  # Vault (griphook)
  # see: https://github.com/recursionpharma/data-science-onboarding#setting-up-griphook
  source $HOME/.griphook/env
fi

########
# PATH #
########

if $IS_WORK_LAPTOP; then
  # Gcloud (update PATH for the Google Cloud SDK)
  # see: https://cloud.google.com/sdk/docs/downloads-interactive
  if [ -f '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/michael.uloth/google-cloud-sdk/path.zsh.inc'; fi
fi

# Pyenv
# NOTE: do NOT use eval "$(pyenv init -)" or eval "$(pyenv virtualenv-init -)" (they slow the shell down a lot)
# see: https://github.com/pyenv/pyenv?tab=readme-ov-file#set-up-your-shell-environment-for-pyenv
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

# openSSL
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

# Rust
export PATH="$HOME/.config/cargo/bin:$PATH"

# Homebrew (keep last so will be at front of PATH)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin/bin:$PATH" # Add Homebrew's executable directory to front of PATH
