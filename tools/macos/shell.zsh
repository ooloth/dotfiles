########################
# ENVIRONMENT VARIABLES #
########################

# TODO: zsh/variables.zsh should find all shell/variables.zsh files and source them

export COMPUTER_NAME=$(/usr/sbin/networksetup -getcomputername)

case "$COMPUTER_NAME" in
  "Air")
      export COMPUTER="air" ;;
  "Mini")
      export COMPUTER="mini" ;;
  *)
      # Default to work for unknown computer names (including explicit "work")
      export COMPUTER="work" ;;
esac

###########
# ALIASES #
###########

is_air() { [[ "$COMPUTER" == "air" ]]; }
is_mini() { [[ "$COMPUTER" == "mini" ]]; }
is_work() { [[ "$COMPUTER" == "work" ]]; }
