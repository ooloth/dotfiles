---
number: 004
status: accepted
date: 2026-10-20
---

# 004 — `u` checks only what would make an update fail, and prints no warnings

## Forced by

`features/update/gcloud-auth.bash` was added on 2026-09-04 (`64e96281`) because Vertex AI
sessions fail silently once gcloud's application-default credentials expire. It runs inside `u`
as a reminder, not because `u` needs the credentials. The maintainer misses warnings in a long
run and wants `u` to report only failures that bear on `u`. The Vertex AI failure belongs where
it happens, in the `cc` alias on the work laptop.

## Decision

A prerequisite check exists only for a dependency that would make one of `u`'s updates fail.
When it fails, it is an error that stops the run (decision 003), never a warning that lets the
run carry on. Concerns outside `u`, such as credentials only a coding session needs, are checked
where they are used.

The gcloud credentials check passes this test only because uv needs them on the work laptop. It
therefore moves to `tools/uv/preflight.bash`, guarded by `is_work`, and
`features/update/gcloud-auth.bash` is removed.

## Rejected

- **Keep reminders in `u` as warnings that do not count as failures.** The maintainer misses
  them in a long run, so a warning does not do the job it exists for. This reverses if `u` gains
  a short summary that the maintainer reads every time.
- **Keep reminders in `u` as errors.** An expired token that no update needs would then block
  every update. This reverses if the reminder's concern becomes a real dependency of an update,
  which is what happened to the gcloud check through uv.

## Risk

A concern that used to be caught by running `u` is now caught only where it is used. The
credentials Vertex AI needs stop being checked by `u` the day uv no longer needs them, so the
`cc` alias has to check them itself.

## Revisit when

A failure that `u` used to catch starts surfacing late somewhere else.

## Also update

- [ ] `features/update/gcloud-auth.bash` is removed, and `features/update/tools.bash` no longer
  lists it
- [ ] the `cc` alias checks gcloud credentials on the work laptop
