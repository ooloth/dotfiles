###########
# ALIASES #
###########

# Log in to each work tool whose credentials have expired (see features/auth/README.md). --offline
# keeps uv away from the work package index, which needs the Google credentials auth refreshes.
if is_work; then
  alias auth="uv run --offline ${DOTFILES}/features/auth/auth.py"
fi
