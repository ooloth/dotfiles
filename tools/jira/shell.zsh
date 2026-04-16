########################
# ENVIRONMENT VARIABLES #
########################

if is_work; then
  # export JIRA_API_TOKEN="" # see: https://id.atlassian.com/manage-profile/security/api-tokens
fi

###########
# ALIASES #
###########

###############
# COMPLETIONS #
###############

if is_work && have jira; then
  eval "$(jira completion zsh)"
fi
