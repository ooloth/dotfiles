source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

###########
# ALIASES #
###########

i() {
  local tool="$1"

  bash "${DOTFILES}/features/install/tools.bash" "$tool";

  printf "\n🔁 Reloading shell\n"
  exec -l "${SHELL}"
}
