---
number: 003
status: accepted
date: 2026-10-20
---

# 003 — `u` stops before updating anything when a prerequisite fails

## Forced by

`features/update/tools.bash` runs every update and reports the failures at the end, so a
missing prerequisite surfaces only after the whole run. On 2026-10-20 that was 1h 12m, followed
by reading through the output to find the cause. The maintainer would rather fix a prerequisite
and rerun straight away than have the run carry on without it.

## Decision

`u` runs every prerequisite check before its first update step: each
`tools/{tool}/preflight.bash` (decision 002) and its own network check. The checks run in
parallel, each with a 5 second timeout. If any fails, `u` prints every failure together, each
with its fix command, and exits without running any update. `u <tool>` runs only that tool's
check.

Measured on the work laptop on 2026-10-20, the slowest candidate check was gcloud minting a
token, at 1.2 s. Testing for the Docker socket file takes no measurable time, while `docker
info` took 2.5 s to fail with the daemon down. One request to `formulae.brew.sh` took 0.1 s. Run
in parallel, the checks take about as long as the slowest one.

## Rejected

- **Report failed prerequisites up front, then skip only the tools that depend on them.** The
  run carries on without the prerequisite, and the skipped update is easy to miss in a long run.
  The maintainer chose to fix and rerun instead. This reverses if a prerequisite is often
  unavailable for reasons the maintainer cannot fix at the time, so stopping would block every
  other update for a long while.
- **Run the checks one after another.** The total wait becomes the sum of every check rather
  than the slowest one. This reverses if a check needs another to pass first.

## Risk

One failed prerequisite blocks every update, including ones that do not need it. Keeping
Homebrew current waits until Docker is started, even though Homebrew never uses Docker.

## Revisit when

A prerequisite fails often for reasons the maintainer cannot fix during the run.

## Also update

- [x] `features/update/tools.bash` runs the checks first
- [x] `README.md`, where `u` is described, says it stops on a failed prerequisite
