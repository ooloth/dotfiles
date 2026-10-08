# Project commands

Facts about the project commands: each `features/*/*.bash` that picks what to run from
`current_dir=$(basename "${PWD}")` and the machine. These are what the shell aliases `check`,
`test`, `start`, `stop`, `restart`, `run`, `new` and `submit` run, and agents, loops and `&&` chains
read their exit status to decide whether the work passed.

- A project command exits non-zero when no case matches the current directory, on work and non-work
  machines. Each no-match branch calls `no_case_defined <command>` from `tools/bash/utils.bash`,
  which exits 1. An exit of 0 there would tell a caller that a check passed when nothing ran.
- The no-match message goes to stderr and names the command and the directory:
  `No '<command>' case defined for '/<dir>'`.
- A command whose case matches exits with its tool's status: 0 with no no-match message when the
  tool succeeds, and the tool's own code when it fails. Cases shared across machines (`agency-*`,
  `agent-*` in `check.bash` and `test.bash`) form the outer `case`, and the machine cases sit under
  its `*)` branch, so a matched shared case cannot fall through to a no-match branch. Each tool call
  in a case goes on its own line: `set -e` ignores a failure on the left of `&&`, so a failing `a`
  in `a && b` skips `b` and the command carries on. Chaining with `&&` loses the status of every
  call but the last.

`scripts/check-project-commands.bash` checks every project command in CI, under macOS `/bin/bash`
with `TERM` unset, and with `COMPUTER` set to choose each machine's branch. It checks the third
property for every matched case, listed in its `MATCHED_CASES` table. Adding, removing or changing
a case means updating that table, and the check fails until you do.
