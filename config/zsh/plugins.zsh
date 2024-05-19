# fnm
eval "$(fnm env --use-on-cd --log-level=error)"

# fzf
eval "$(fzf --zsh)"

# github-copilot-cli
eval "$(github-copilot-cli alias -- "$0")"

# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source $(brew --prefix)/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme
source $HOME/.config/zsh/p10k.zsh # to customize, run `p10k configure` or edit config/zsh/p10k.zsh

# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if $IS_WORK_LAPTOP; then
  # Gcloud (command completion)
  if [ -f '/Users/michael.uloth/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/michael.uloth/google-cloud-sdk/completion.zsh.inc'; fi
fi