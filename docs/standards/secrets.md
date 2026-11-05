# Secrets

How commands in this repo's shells and scripts get the secrets they need, so no secret reaches
shell history, the clipboard or a tracked file. `features/secret/README.md` explains the commands,
and `warn_secret_in_history` in `tools/zsh/config/hooks.zsh` keeps a line holding a literal secret
out of `~/.zsh_history`.

**Should: a command that needs a secret reads it from the login Keychain, and the secret is stored
there first.** Store it once with `secret add <name>`, which asks for the value without showing
it, so it never reaches shell history, the clipboard or a command you typed. Pass it as
`"$(secret get <name>)"`. A tool that keeps its own credential after a one-time login, such as
`codefresh auth create-context` writing `~/.cfconfig`, is the exception for later runs, but the
one-time login still reads the secret this way. Setup docs in this repo give the `secret add` step,
never an instruction to paste a value into a command. This is this repo's choice for the
commands its shells and scripts run. Another project may keep its secrets in another store, such as
1Password, for reasons its own records give.
