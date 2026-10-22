########################
# ENVIRONMENT VARIABLES #
########################

# The API token lives in the login keychain, never in JIRA_API_TOKEN (see README.md)

###########
# ALIASES #
###########

###############
# COMPLETIONS #
###############

if is_work && have jira; then
  eval "$(jira completion zsh)"
fi
