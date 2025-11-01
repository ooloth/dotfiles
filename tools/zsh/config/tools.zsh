# Add tool-specific environment variables, aliases and completions to zsh environment

############################
# COMPLETE SHELL.ZSH FILES #
############################

# Find all shell.zsh files in each tool directory (except @new and @archive)
shell_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell.zsh" -print))

for file in "${shell_files[@]}"; do
  source "${file}"
done

#####################################
# LEGACY: SHELL/VARIABLES.ZSH FILES #
#####################################

# Find all shell/variables.bash files in each tool directory (except @new and @archive and zsh)
shell_variables_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/variables.zsh" -print))

for file in "${shell_variables_files[@]}"; do
  source "${file}"
done

###################################
# LEGACY: SHELL/ALIASES.ZSH FILES #
###################################

#######################################
# LEGACY: SHELL/INTEGRATION.ZSH FILES #
#######################################

# Find all shell/integration.bash files in each tool directory (except @new and @archive)
shell_integration_files=($(find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/integration.zsh" -print))

for file in "${shell_integration_files[@]}"; do
  source "${file}"
done

###################################
# LEGACY: ONE-OFF VARIABLES SETUP #
###################################

#################################
# LEGACY: ONE-OFF ALIASES SETUP #
#################################

####################################
# LEGACY: ONE-OFF COMPLETION SETUP #
####################################

# FIXME: crashes terminal if set -e is enabled
# powerlevel10k
# see: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#homebrew
source "/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
source "${DOTFILES}/tools/powerlevel10k/config/p10k.zsh" # to customize, run `p10k configure` or edit zsh/config/p10k.zsh

# docker
fpath=("${HOME}/.docker/completions" $fpath)

if have fzf; then
  eval "$(fzf --zsh)"
fi

if have uv; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi

