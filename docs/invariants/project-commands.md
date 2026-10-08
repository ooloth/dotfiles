# Project commands

Facts about how the `features/{name}/{name}.bash` project commands (`check`, `new`, `restart`,
`run`, `start`, `stop`, `submit`, `test`) behave. Chained calls such as `check && submit` depend
on them.

- A project command picks what to run from the basename of `$PWD` and, where it splits by machine,
  from `is_work`. When nothing matches, it prints `No '{name}' case defined for '/{dir}'` on stderr,
  prints nothing on stdout, and exits 1. This holds at every no-match site, on every machine.
- A matched case never reaches a no-match branch. It exits with its tool's status, so a passing tool
  exits 0 and a failing one passes its code through.
- `scripts/check-project-commands.bash` checks both in CI, for every `features/{name}/{name}.bash`
  that contains the no-match message, under each machine type.
