#!/usr/bin/env bash
# Starts Claude Code with the permission mode for this machine, told where the repos related to the
# current repo are cloned. A repo with no entry starts exactly as plain
# `claude --permission-mode <mode>`.
#
# Related repos are named in the system prompt rather than added with --add-dir, because a clone is
# a working checkout that may be on any branch: adding it would load its CLAUDE.md and present its
# files as current, while a hint lets the session check before relying on it.
#
# Run with: cc [claude arguments], or ccc to continue the last session. A first argument of
# --unattended starts in auto mode on every machine, for a session nobody watches as it starts.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../tools/bash/utils.bash"

# Repos a session in the named folder should be told about, one name per line, each cloned beside
# the current repo's main checkout. The pairs come from PRIVATE_RELATED_REPOS in private.env, as
# space-separated FOLDER_PREFIX=RELATED_REPO, because the repos' names are private. A prefix matches
# the repo's worktrees and clones beside it too. Only the work laptop has related repos, and there
# an unset key is named on stderr; one set but empty means no pairs.
related_repos() {
  if ! is_work; then
    return 0
  fi
  if [[ -z "${PRIVATE_RELATED_REPOS+set}" ]]; then
    printf '⚠️  PRIVATE_RELATED_REPOS is unset (see private.env.example), so no related repos are named\n' >&2
    return 0
  fi
  local pair pairs=()
  read -r -a pairs <<<"${PRIVATE_RELATED_REPOS}"
  # The guarded expansion keeps an empty list from failing under bash 3.2's set -u
  for pair in ${pairs[@]+"${pairs[@]}"}; do
    if [[ "$1" == "${pair%%=*}"* ]]; then
      printf '%s\n' "${pair#*=}"
    fi
  done
}

# The folder holding the current repo's main checkout, so every worktree of a repo gets the same
# answer, or the current folder's parent outside a git repo
org_folder() {
  local common
  if common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    dirname "$(dirname "${common}")"
  else
    dirname "${PWD}"
  fi
}

# The system prompt line about one related repo, given its name and where it should be cloned
# shellcheck disable=SC2016 # The backticks are markdown for the session, not command substitution
related_repo_hint() {
  local name="$1" path="$2"
  if [[ ! -d "${path}" ]]; then
    printf 'Related repo: `%s` is not cloned at `%s`.\n' "${name}" "${path}"
    return 0
  fi
  printf 'Related repo: `%s` at `%s`. It is a working checkout that may be on a feature branch or behind origin. To read origin'\''s current default branch, run `git -C <path> fetch origin` and then `git -C <path> show origin/HEAD:<file>`. Don'\''t change its branch or files; to change that repo, add a worktree beside it.\n' \
    "${name}" "${path}"
}

main() {
  local mode="bypassPermissions"
  if is_work; then
    mode="auto"
    # Every work session can then use Vertex AI, so setting CLAUDE_CODE_USE_VERTEX in the settings
    # file moves it there when a usage limit is reached or a turn fails on a rate limit. The project
    # and region do nothing while that switch is "". The project is private, so it comes from
    # private.env rather than the tracked settings file.
    if [[ -n "${PRIVATE_VERTEX_PROJECT:-}" ]]; then
      export ANTHROPIC_VERTEX_PROJECT_ID="${PRIVATE_VERTEX_PROJECT}" CLOUD_ML_REGION=global
    fi
  fi

  local claude_args=() org hints="" name
  # A session nobody watches as it starts, such as one monitor-prs opens to draft replies, reads
  # text other people wrote. It runs in auto mode on every machine, so a classifier checks each
  # action and blocks one that looks driven by that text. The skill's instructions hold its posts
  # and pushes for approval, but auto mode itself approves a push to the session's own repo, so
  # against a session steered by what it read, the classifier is the only guard that runs. Ask
  # rules were tried and dropped: their prompts showed long gh commands cut short, which could not
  # be reviewed.
  local unattended=false
  if [[ "${1:-}" == "--unattended" ]]; then
    shift
    mode="auto"
    unattended=true
  fi
  # A work session someone is watching runs auth first, which opens a browser login for each work
  # tool whose credentials have expired and waits for it, so the session doesn't meet an expired
  # login later, such as after a switch to Vertex AI. The session starts whatever auth finds. One
  # nobody watches skips it, since a login waiting with nobody there would stop it starting.
  if is_work && [[ "${unattended}" == false ]]; then
    uv run --offline "${DOTFILES}/features/auth/auth.py" || true
  fi
  org="$(org_folder)"
  while IFS= read -r name; do
    hints+="$(related_repo_hint "${name}" "${org}/${name}")"$'\n'
  done < <(related_repos "$(basename "${PWD}")")
  if [[ -n "${hints}" ]]; then
    claude_args+=(--append-system-prompt "${hints%$'\n'}")
  fi

  # The guarded expansion keeps an empty list from failing under bash 3.2's set -u
  exec claude --permission-mode "${mode}" ${claude_args[@]+"${claude_args[@]}"} "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
