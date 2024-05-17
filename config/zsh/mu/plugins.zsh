# fnm
eval "$(fnm env --use-on-cd --log-level=error)"

# fzf
eval "$(fzf --zsh)"

# prompt
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source $(brew --prefix)/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme
source $HOME/.config/zsh/mu/.p10k.zsh # to customize, run `p10k configure` or edit config/zsh/mu/.p10k.zsh
# eval "$(starship init zsh)"

# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# github-copilot-cli
eval "$(github-copilot-cli alias -- "$0")"
