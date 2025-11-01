#############
# AUTOMATIC #
#############

# Find all shell/integration.bash files in each tool directory (except @new and @archive)
shell_integration_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/integration.zsh" -print))

for file in "${shell_integration_files[@]}"; do
  source "${file}"
done

##########
# MANUAL #
##########

# FIXME: crashes terminal if set -e is enabled
# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source "/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
source "${DOTFILES}/tools/powerlevel10k/config/p10k.zsh" # to customize, run `p10k configure` or edit zsh/config/p10k.zsh

# docker
fpath=(/Users/michael.uloth/.docker/completions $fpath)

if have fzf; then
  eval "$(fzf --zsh)"
fi

if have uv; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi

