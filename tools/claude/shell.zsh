
########################
# ENVIRONMENT VARIABLES #
########################

# See: https://code.claude.com/docs/en/env-vars
# See: https://code.claude.com/docs/en/model-config#environment-variables
# See: https://docs.anthropic.com/en/docs/about-claude/models/overview#model-names
# See: https://code.claude.com/docs/en/model-config#model-aliases
export ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4-5-20251001
export ANTHROPIC_MODEL=opus
export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1

# Agents have been complaining about frequent TaskCreate reminders
# See: https://github.com/anthropics/claude-code/issues/43311#issuecomment-4185513335
export CLAUDE_CODE_ENABLE_TASKS=0

export CLAUDE_CODE_ENABLE_TELEMETRY=0

# A session started with --add-dir loads that folder's CLAUDE.md only when this is set
export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1

# Default is 200, which I've hit in research-heavy sessions
export CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION=999

export DISABLE_ERROR_REPORTING=1
export DISABLE_TELEMETRY=1

# if is_work; then
  # export ANTHROPIC_MODEL=sonnet
  # Work uses subscription login instead of Vertex AI now (/login -> subscription -> work email address)
  # export CLAUDE_CODE_USE_VERTEX=0
  # export CLOUD_ML_REGION=global
# fi

###########
# ALIASES #
###########

# cc.bash picks the permission mode for this machine and adds the repo's related folders
# TODO: consider auto at home after testing it at work for awhile (it uses more tokens)
# TODO: at work, consider a granular allowList if risky actions sneak through or redundant model-checking token use is too wasteful or slow
if is_work; then
  # Sessions at work use the work tools, and Vertex AI needs the Google credentials, so each start
  # runs auth, which opens a browser login only for each one whose check says it has expired. A
  # check that can't reach its service opens nothing, and the session starts either way. This adds
  # about a second to each start. See decision 004's addenda. An alias left by an earlier version
  # of this file would win over the functions.
  unalias cc ccc 2>/dev/null
  function claude_work_logins {
    uv run --offline "${DOTFILES}/features/auth/auth.py"
  }
  function cc {
    claude_work_logins
    bash "${DOTFILES}/tools/claude/cc.bash" "$@"
  }
  function ccc {
    claude_work_logins
    bash "${DOTFILES}/tools/claude/cc.bash" --continue "$@"
  }
else
  alias cc="bash ${DOTFILES}/tools/claude/cc.bash"
  alias ccc="bash ${DOTFILES}/tools/claude/cc.bash --continue"
fi

if is_work; then
  # Fallback to Vertex AI for current session only if I hit my subscription quota (Max 20x limit, I think)
  ccy-vertex() {
    if [[ -z "${PRIVATE_VERTEX_PROJECT:-}" ]]; then
      error "PRIVATE_VERTEX_PROJECT is unset (see private.env.example), so there is no Vertex AI project"
      return 1
    fi

    claude_work_logins

    # Point to Vertex AI for this session only
    claude --settings '{"env":{"CLAUDE_CODE_USE_VERTEX":"1","CLOUD_ML_REGION":"global","ANTHROPIC_VERTEX_PROJECT_ID":"'"${PRIVATE_VERTEX_PROJECT}"'"}}' --dangerously-skip-permissions "$@"
  }
fi
