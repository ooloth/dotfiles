eval "$(/opt/homebrew/bin/brew shellenv)"

# On work laptop only
if [ -d "$HOME/Repos/recursionpharma" ]; then
  source "$HOME/.config/netskope/env.sh"
  # Instruction to add it came from here: https://github.com/recursionpharma/data-science-onboarding/wiki/4.-Local-Environment-Setup#installing-pyenv-on-macos
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  # TODO: can I remove this (for performance)?
  eval "$(pyenv init --path)"
fi
