
########################
# ENVIRONMENT VARIABLES #
########################

###########
# ALIASES #
###########

if have tailscale; then
  alias mini="tailscale ssh michael@mini" # automatically log in using SSH key pair
elif have kitten; then
  alias mini="kitten ssh michael@mini.local"       # automatically log in using SSH key pair
else
  alias mini="ssh michael@mini.local"
fi



