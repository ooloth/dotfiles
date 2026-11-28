########################
# ENVIRONMENT VARIABLES #
########################

# For bash scripts, see tools/macos/utils.bash. For Brewfiles, see tools/macos/computer.rb.
# A name inherited from the parent shell came from this same Mac, so it is kept rather than asked for
# again. That saves a subprocess on every shell start, and this file is sourced twice per shell.
# scutil reads the same ComputerName that `networksetup -getcomputername` prints, in 4 ms, not 12.
# An Amp orb, which sets AMP_ORB=1, is never for work and has no scutil, so it is "orb" without
# asking for a name.
if [[ "${AMP_ORB:-}" == "1" ]]; then
  export COMPUTER="orb"
else
  export COMPUTER_NAME="${COMPUTER_NAME:-$(/usr/sbin/scutil --get ComputerName)}"

  case "$COMPUTER_NAME" in
    "Air")
        export COMPUTER="air" ;;
    "Mini")
        export COMPUTER="mini" ;;
    *)
        # Default to work for unknown computer names (including explicit "work")
        export COMPUTER="work" ;;
  esac
fi

#############
# FUNCTIONS #
#############

is_air() { [[ "$COMPUTER" == "air" ]]; }
is_mini() { [[ "$COMPUTER" == "mini" ]]; }
is_work() { [[ "$COMPUTER" == "work" ]]; }
is_orb() { [[ "$COMPUTER" == "orb" ]]; }
