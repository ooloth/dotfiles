
########################
# ENVIRONMENT VARIABLES #
########################

# See: https://code.claude.com/docs/en/env-vars
# See: https://code.claude.com/docs/en/model-config#environment-variables
# See: https://code.claude.com/docs/en/model-config#model-aliases
# See: https://docs.anthropic.com/en/docs/about-claude/models/overview#model-names
export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4-5-20251001
export ANTHROPIC_MODEL=opus
export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1
export CLAUDE_CODE_ENABLE_TELEMETRY=0
export DISABLE_ERROR_REPORTING=1
export DISABLE_TELEMETRY=1

# Agents have been complaining about frequent TaskCreate reminders
# See: https://github.com/anthropics/claude-code/issues/43311#issuecomment-4185513335
export CLAUDE_CODE_ENABLE_TASKS=0

if is_work; then
  export ANTHROPIC_MODEL=sonnet
  # See: https://github.com/recursionpharma/ai-coding-guild-docs/blob/trunk/public/claude/settings.json
  # export ANTHROPIC_VERTEX_PROJECT_ID=vertexai-sandbox-e8a925d0
  # Work uses subscription login instead of Vertex AI now (/login -> subscription -> work email address)
  # export CLAUDE_CODE_USE_VERTEX=0
  # export CLOUD_ML_REGION=global
fi

###########
# ALIASES #
###########

# TODO: consider auto after testing it at work for awhile (it uses more tokens)
alias cc="claude --permission-mode bypassPermissions"

if is_work; then
  # TODO: consider granular allowList if risky actions sneak through or redundant model-checking token use is too wasteful or slow
  alias cc="claude --permission-mode auto"
  # Fallback to Vertex AI for current session only if I hit my subscription quota (Max 20x limit, I think)
  # See: https://recursion.atlassian.net/wiki/spaces/guildaicoding/pages/3943825434/Claude+Code+Installation
  ccy-vertex() {
    # Vertex AI requires gcloud credentials to be valid, so check that first
    if timeout 5 gcloud auth application-default print-access-token &>/dev/null; then
      debug "✅ gcloud credentials are valid"
    else
      warn "⚠️ gcloud reauthentication needed — opening browser to reauthenticate..."
      gcloud auth login --update-adc
    fi

    # Point to Vertex AI for this session only
    claude --settings '{"env":{"CLAUDE_CODE_USE_VERTEX":"1","CLOUD_ML_REGION":"global","ANTHROPIC_VERTEX_PROJECT_ID":"vertexai-sandbox-e8a925d0"}}' --dangerously-skip-permissions "$@"
  }
fi
