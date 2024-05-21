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
