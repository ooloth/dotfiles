eval "$(/opt/homebrew/bin/brew shellenv)"

# On work laptop only
if [ -d "$HOME/Repos/recursionpharma" ]; then
  eval "$(pyenv init --path)"
fi 