# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# On work laptop only
if [ -d "$HOME/Repos/recursionpharma" ]; then
  source "$HOME/.config/netskope/env.sh"
fi

