# Project commands

Facts about the project commands (`check`, `new`, `restart`, `run`, `start`, `stop`, `submit`,
`test`): the `features/*/*.bash` scripts that pick what to run from the name of the current
directory and the machine. Their only callers are the shell aliases in `features/*/shell.zsh`, which
read the exit status to tell whether anything ran.

- A project command exits non-zero when no case matches the current directory, on every machine. It
  prints `🚨 No '<command>' case defined for '/<directory>'` to stderr first. Every no-match branch
  calls `no_case_defined <command>` from `tools/bash/utils.bash`, which owns that message and the
  exit code.
- A project command whose case matches exits with its tool's status: 0 when the tool succeeds, with
  no no-match message, and the tool's own code when it fails. Cases shared across machines form the
  outer `case`, with the machine-specific `case` under its `*)` branch, so a matched shared case
  never reaches a no-match branch.
- Sourcing `tools/macos/utils.bash` keeps a `COMPUTER` that is already set and detects the machine
  only when it is unset, so a caller can choose which machine's branch a command takes.

`scripts/check-project-commands.bash` checks all three in CI, over every `features/*/*.bash` that
reads the current directory, on the work machine and on a personal one.
