
########################
# ENVIRONMENT VARIABLES #
########################

# Claude Code settings that are the same on every machine live in the `env` block and the `model`
# key of tools/claude/config/settings.json, not here. A session the Rex launcher
# (tools/rex/claude-tab.bash) opens starts through the login shell Rex uses for commands, which is
# not interactive and so never reads .zshrc or this file, while Claude Code reads settings.json
# however it was launched. A value in that `env` block also replaces the same variable exported
# here.
#
# Why some of the settings.json `env` values are set, since JSON holds no comments:
# - CLAUDE_CODE_SUBAGENT_MODEL=sonnet: an Agent call that names no model runs on Sonnet rather than
#   the session's Opus. A model the call or the agent's definition names still wins (Claude Code
#   2.1.251 or later), and Explore and Plan keep their own.
#   See: https://code.claude.com/docs/en/sub-agents#choose-a-model
# - CLAUDE_CODE_ENABLE_TASKS=0: agents complained about frequent TaskCreate reminders.
#   See: https://github.com/anthropics/claude-code/issues/43311#issuecomment-4185513335
# - CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1: a session started with --add-dir loads that
#   folder's CLAUDE.md only when this is set.
# - CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION=999: the default of 200 runs out in research-heavy
#   sessions.
# See: https://code.claude.com/docs/en/model-config#environment-variables
# See: https://code.claude.com/docs/en/env-vars
#
# Only what differs by machine belongs here. An ANTHROPIC_MODEL exported here beats settings.json's
# `model` (https://code.claude.com/docs/en/model-config#setting-your-model), but only for sessions
# started from zsh, such as `cc`.

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
  # Sessions at work use the work tools, so each start runs auth, which opens a browser login only
  # for each one whose check says it has expired. A check that can't reach its service opens
  # nothing, and the session starts either way. This adds about a second to each start. See
  # decision 004's addenda. A `cc` or `ccc` alias already defined in the shell, such as one from a
  # shell started before this file defined functions, would win over the functions.
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

# Replays unattended planning on a ticket already planned by hand, for grading (see the script's docstring)
alias replay="uv run ${DOTFILES}/tools/claude/replay.py"

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
