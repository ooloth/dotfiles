
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
# - CLAUDE_CODE_USE_VERTEX="": the switch that moves every running session to Vertex AI when it is
#   "1". The value "" means the subscription, and stays in the file because removing the key would
#   not move a running session back. tools/claude/tests/test_settings.py fails when the last
#   commit holds "1".
# See: https://code.claude.com/docs/en/model-config#environment-variables
# See: https://code.claude.com/docs/en/env-vars
#
# Only what differs by machine belongs here. An ANTHROPIC_MODEL exported here beats settings.json's
# `model` (https://code.claude.com/docs/en/model-config#setting-your-model), but only for sessions
# started from zsh, such as `cc`.


###########
# ALIASES #
###########

# cc.bash picks the permission mode for this machine, adds the repo's related folders and, on the
# work laptop, runs the work logins
alias cc="bash ${DOTFILES}/tools/claude/cc.bash"
alias ccc="bash ${DOTFILES}/tools/claude/cc.bash --continue"

if is_work; then
  # Moves every session to Vertex AI or back, or with no argument says which one they use. The
  # status line and the StopFailure hook do this on their own (see tools/claude/README.md); this is
  # for when they don't, or to move early. Run it in a session as `! cc-switch`.
  cc-switch() {
    # The project comes from private.env, so this works in a terminal as well as in a session
    ANTHROPIC_VERTEX_PROJECT_ID="${PRIVATE_VERTEX_PROJECT:-}" \
      uv run --offline --script "${DOTFILES}/tools/claude/provider_switch.py" "$@"
  }

  # Starts a session that stays on Vertex AI whatever the switch in settings.json says. It starts
  # through cc.bash, so it gets the permission mode, related repos and Vertex AI project `cc` gets.
  # cc.bash's --vertex adds the --settings that outranks the user settings file, and refuses to
  # start when PRIVATE_VERTEX_PROJECT is empty, as it does for a repo that must always use Vertex AI.
  cc-vertex() {
    bash "${DOTFILES}/tools/claude/cc.bash" --vertex "$@"
  }
fi
