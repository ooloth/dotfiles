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
  cached_completion jira jira completion zsh
fi
