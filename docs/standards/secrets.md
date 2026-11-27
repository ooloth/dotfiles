# Secrets

How commands in this repo's shells and scripts get the secrets they need, so no secret reaches
shell history, the clipboard or a tracked file. `features/secret/README.md` explains the commands.
`warn_secret_in_history` in `tools/zsh/config/hooks.zsh` keeps a line out of `~/.zsh_history` when
it holds a literal value in one of the shapes that README lists, such as after `--api-key` or in
`JIRA_API_TOKEN=`. It is a safety net for those shapes, not a guarantee for every secret.

**Should: a command that needs a secret reads it from the login Keychain, and the secret is stored
there first.** Store it once with `secret add <name>`, which asks for the value without showing it,
so it never reaches shell history, the clipboard or a command you typed. Pass it to that one command
as a variable set for the command alone, `TOKEN="$(secret get <name>)" tool`, where the tool reads
one from its environment, and otherwise as an argument, `--token "$(secret get <name>)"`. An
argument is visible to other users on the machine in the process list while the command runs, as the
security standard's Should on commands says. A tool that keeps its own credential after a one-time
login, such as `codefresh auth create-context` writing `~/.cfconfig`, is the exception for later
runs, but the one-time login still reads the secret this way. Setup docs in this repo give the
`secret add` step, never an instruction to paste a value into a command. A script an agent runs
reads its secret differently: it reads it from the login Keychain itself rather than taking it in
the command, so the secret never appears in a command the agent writes or in what the agent reads
back, as `tools/agents/config/skills/use-jira/scripts/fetch_jira_backlog.py` does. This is this
repo's choice for the commands its shells and scripts run. Another project may keep its secrets in
another store, such as 1Password, for reasons its own records give.
