# Project commands

Facts about the project commands (`check`, `new`, `restart`, `run`, `start`, `stop`, `submit`,
`test`): the `features/*/*.bash` scripts that pick what to run from the name of the current
directory and the machine. Their only callers are the shell aliases in `features/*/shell.zsh`, which
read the exit status to tell whether anything ran.

- A project command exits non-zero when no case matches the current directory, on every machine. It
  first prints a banner to stderr containing `🚨 No '<command>' case defined for '/<directory>'`.
  Every no-match branch calls `no_case_defined <command>` from `tools/bash/utils.bash`, which owns
  that message and the exit code.
- A project command whose case matches exits with its tool's status: 0 when the tool succeeds, with
  no no-match message, and the tool's own code when it fails. Cases shared across machines form the
  outer `case`, with the machine-specific `case` under its `*)` branch, so a matched shared case
  never reaches a no-match branch.
- Sourcing `tools/macos/utils.bash` keeps a `COMPUTER` that is already set and detects the machine
  only when it is unset, so a caller can choose which machine's branch a command takes.
- Every project command reads its directory with `current_dir=$(basename "${PWD}")`. That line is
  how `scripts/check-project-commands.bash` finds the commands to check, so a command that reads
  its directory any other way is not checked. The check prints the commands it found.
- The shared-project labels the check runs `check` and `test` in (`agency-1`, `agency-2`,
  `agent-1`, `agent-2`) are hard-coded in the check. A new shared case in `check.bash` or
  `test.bash` is added to its `SHARED_PROJECTS` too.

`scripts/check-project-commands.bash` checks the first three in CI, on the work machine and on a
personal one.
