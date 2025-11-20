
########################
# ENVIROMENT VARIABLES #
########################

###########
# ALIASES #
###########

# Use stern as a replacement for kubectl logs
# Tails a pod regex or "resource/name" and shows logs for any containers that match the regex
# Add -c regex to filter by container name
# see: https://github.com/stern/stern#usage
if have stern; then
  alias kl="stern"
fi

###############
# COMPLETIONS #
###############

