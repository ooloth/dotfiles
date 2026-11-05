###########
# ALIASES #
###########

# Store a secret in the login Keychain once, then pass it as "$(secret get <name>)" (see
# features/secret/README.md). warn_secret_in_history in tools/zsh/config/hooks.zsh points here.
alias secret="uv run --offline ${DOTFILES}/features/secret/secret.py"
