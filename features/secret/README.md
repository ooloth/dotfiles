# secret

Keeps secrets out of shell history by storing them in the login Keychain and reading them into
commands. **A secret goes into the Keychain first**, and every command that needs it reads it from
there:

```sh
secret add codefresh   # once: asks for the value without showing it
codefresh auth create-context --api-key "$(secret get codefresh)"
```

- **`secret add <name>`** asks for the value with input hidden, and stores it under `<name>`,
  replacing any value already there. Pasting works, and so do tokens longer than 128 characters,
  which `security`'s own prompt cuts short. It prints how many characters it stored, so a cut-off
  paste shows up at once. Piped input is read as one line.
- **`secret get <name>`** prints the value and nothing else on stdout. When nothing is stored
  under the name, it prints nothing there, exits 1 and says to run `secret add <name>` first.
  It finds items stored by other tools too, such as `jira-cli`, because it looks only at the name.
- **Where the value goes:** into the login Keychain, which stays on this Mac. While
  `security add-generic-password` runs, the value is one of its arguments, so another process
  running as you could see it in `ps` during that moment. It never reaches shell history, the
  clipboard or a command you typed.

`warn_secret_in_history` in `tools/zsh/config/hooks.zsh` keeps a line with a literal secret out of
`~/.zsh_history` and points here. A line that passes `"$(secret get <name>)"` is saved as normal.

Tests: `uv run features/secret/tests/test_secret.py`. They use a `security` stub and never touch
the real Keychain.
