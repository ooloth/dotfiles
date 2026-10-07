# Project commands

Facts about the project commands in `features/` (`check`, `new`, `restart`, `run`, `start`,
`stop`, `submit`, `test`): scripts that choose what to run from the basename of the current
directory and, for most projects, from which machine they run on. The shell aliases in each
`features/*/shell.zsh` call them, and a caller can only tell success from failure by the exit
status.

- A project command exits non-zero when it has no case for the current directory, on work and
  non-work machines alike. Every no-match branch calls `no_case_defined <command>` in
  `tools/bash/utils.bash`, which exits 1. Calling it rather than `error` alone is what keeps a
  missing case from looking like success.
- That no-match prints `🚨 No '<command>' case defined for '/<dir>'` to stderr, naming the command
  and the directory, which is all that's needed to reproduce it.
- A command whose case matches exits with its tool's status: 0 with no no-match message when the
  tool succeeds, and the tool's own code when it fails. In `check.bash` and `test.bash`, the
  projects shared across machines (`agency-*`, `agent-*`) form the outer `case` and the
  machine-specific `case` sits under its `*)` branch, so a matched shared project cannot fall
  through to a no-match branch.

`scripts/check-project-commands.bash` checks all three in CI, for every `features/*/*.bash` that
dispatches on `current_dir=$(basename …)`, under macOS `/bin/bash` with `TERM` unset and with
`COMPUTER` set to each machine in turn. `tools/macos/utils.bash` keeps a `COMPUTER` that is already
set, which is how the check chooses the machine.
