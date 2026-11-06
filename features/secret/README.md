# secret

Keeps secrets out of shell history by storing them in the login Keychain and reading them into
commands. **A secret goes into the Keychain first**, and every command that needs it reads it from
there:

```sh
secret add codefresh   # once: asks for the value without showing it
docker run --rm -it -v ~/.cfconfig:/root/.cfconfig codefresh/cli \
  auth create-context --api-key "$(secret get codefresh)"
```

The `codefresh` on `PATH` mounts `~/.cfconfig` read-only, so a login that writes it runs the image
directly, as above.

- **`secret add <name>`** asks for the value with input hidden, and stores it under `<name>`,
  replacing the value already stored under that name and account. Pasting works, and so do tokens
  longer than 128 characters, which `security`'s own prompt cuts short. It prints how many
  characters it stored, so a cut-off paste shows up at once. Piped input is read as one line.
  Ctrl-C or Ctrl-D at the prompt stores nothing. `--account <account>` stores it under the account
  a tool looks up, such as `secret add jira-cli --account <your-work-email>`; the default is your
  user name. When the name is already stored under a different account, it stores nothing and
  says to pass that account with `--account`, naming it when `security` shows it. A second item
  under the same name would leave `secret get` returning either value.
- **`secret get <name>`** prints the value and nothing else on stdout. When nothing is stored
  under the name, it prints nothing there, exits 1 and says to run `secret add <name>` first.
  It finds items stored by other tools too, such as `jira-cli`, because it looks only at the name.

## What it protects against

It stops the accidents that copy a secret somewhere it stays:

- **Shell history.** A secret typed into a command lands in `~/.zsh_history`. From there it is
  copied into every backup of your home folder, shown by Ctrl-R history search on a shared screen,
  and read by any script or agent that searches history.
- **The clipboard.** A pasted secret stays in clipboard history, such as Raycast's, and Universal
  Clipboard can send it to your other Apple devices.
- **Exported variables.** `export JIRA_API_TOKEN=…` hands the value to every process the shell
  starts, agents included, and to anything that prints the environment. `"$(secret get <name>)"`
  gives it to one command only.
- **Tracked files.** This repo is public, and setup docs give the `secret add` step rather than a
  value to paste.
- **The screen.** `secret add` hides the value as you type or paste it.

It does not stop a process running as you that sets out to read a secret. Items stored with
`security` trust `security`, so malware, a compromised dependency, or an agent that decides to can
run `secret get <name>` and get the value with no prompt. In Claude Code,
`tools/claude/config/settings.json` denies Bash commands containing `secret get` or
`secret.py get`, which stops an agent that runs the command as written here, along with any
command that merely contains that text. The rules match the command's text, so the same call
spelled another way, such as with `'get'` in quotes, still runs. Claude Code's permissions docs say
the same: a Bash rule isn't a security boundary. For a step that needs your approval on every read,
use 1Password, which asks for Touch ID, at the cost of that prompt each time. The value also
passes through `security add-generic-password`'s arguments while `secret add` runs.

`warn_secret_in_history` in `tools/zsh/config/hooks.zsh` keeps a line out of `~/.zsh_history`
and points here when it holds a literal value after one of these:

- a flag ending in `-key`, `-password`, `-secret` or `-token`, such as `--api-key` or
  `--access-token`, then `=`, spaces or tabs
- `Bearer` or `bearer`, then spaces or tabs
- a name ending in `_TOKEN`, `_SECRET`, `_KEY` or `_PASSWORD`, then `=`

A value starting with `$` is a reference and is saved as normal, so `"$(secret get <name>)"` is
too. A `$'…'` value counts as literal. A value starting with `~`, `/` or `.` is a path and is
saved. Any other shape is saved as typed, such as a bare `TOKEN=…`, a lowercase name or a secret
inside a URL. A held-back line stays out of every write zsh makes on its own, but `fc -W` and
`fc -A` write it anyway.

Tests: `uv run features/secret/tests/test_secret.py`. They use a `security` stub and never touch
the real Keychain.
