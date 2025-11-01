source "${DOTFILES}/tools/zsh/utils.zsh" # have, is_work

########################
# ENVIROMENT VARIABLES #
########################

# See: https://docs.anthropic.com/en/docs/claude-code/settings#environment-variables
# See: https://docs.anthropic.com/en/docs/about-claude/models/overview#model-names
export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-1-20250805
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-5-20250929
export ANTHROPIC_MODEL=claude-sonnet-4-5-20250929
# export ANTHROPIC_MODEL=opusplan
export CLAUDE_CODE_ENABLE_TELEMETRY=0
export DISABLE_ERROR_REPORTING=1
export DISABLE_TELEMETRY=1

if is_work; then
  export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-4-1@20250805
  export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-4-5@20250929
  export ANTHROPIC_MODEL=claude-sonnet-4-5@20250929
  export ANTHROPIC_VERTEX_PROJECT_ID=vertexai-sandbox-e8a925d0
  export CLAUDE_CODE_USE_VERTEX=1
  export CLOUD_ML_REGION=us-east5
  export DISABLE_PROMPT_CACHING=1
fi

###########
# ALIASES #
###########

alias cc="claude"
alias ccy="claude --dangerously-skip-permissions"

