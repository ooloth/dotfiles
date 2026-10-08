# Project commands

Facts about how the `features/{name}/{name}.bash` project commands (`check`, `new`, `restart`,
`run`, `start`, `stop`, `submit`, `test`) behave. Chained calls such as `check && submit` depend
on them.

- A project command picks what to run from the basename of `$PWD` and, where it splits by machine,
  from `is_work`. When nothing matches, it prints `No '{name}' case defined for '/{dir}'` on stderr,
  prints nothing on stdout, and exits 1. This holds at every no-match site, on every machine.
- A matched case never reaches a no-match branch. It exits with its tool's status, so a passing tool
  exits 0 and a failing one passes its code through.

`scripts/check-project-commands.bash` runs in CI and observes part of this. It runs every
`features/{name}/{name}.bash` that contains the no-match message, on Air, Mini and Work:

- In an unmatched directory, each command exits 1, prints the message on stderr and prints nothing
  on stdout.
- In `agency-1` and `agent-1`, `check` and `test` exit with a stub `uv`'s status (0 and 3) and never
  print the no-match message.
- In those runs, errexit, nounset and pipefail are still on when the command exits.
- `error()` in `tools/bash/utils.bash` prints its message and returns without exiting.

The check never runs the matched cases inside the per-machine dispatch, so it cannot see a renamed
or broken one there.
