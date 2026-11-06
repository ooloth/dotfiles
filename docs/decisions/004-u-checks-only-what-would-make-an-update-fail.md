---
number: 004
status: accepted
date: 2026-10-20
amended: 2026-11-05
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

- [x] `features/update/gcloud-auth.bash` is removed, and `features/update/tools.bash` no longer
  lists it
- [x] the `cc` alias checking gcloud credentials on the work laptop is dropped (see the addendum;
  the 2026-11-05 addendum reverses this)

## Addendum (2026-10-20) — the `cc` check is dropped

The maintainer chose not to add a gcloud credentials check to the `cc` alias. Nothing checks
those credentials before a Claude session starts, so a session that needs them finds out when a
`gcloud` command fails. `ccy-vertex` in `tools/claude/shell.zsh` still checks them before starting
a Vertex AI session.
The 2026-11-05 addendum below reverses this: `cc`, `ccc` and `ccy-vertex` all run `auth`.

## Addendum (2026-11-05) — `cc` checks the Google login again

The maintainer chose to have `cc`, `ccc` and `ccy-vertex` on the work laptop check the work
logins before a session starts, which reverses the addendum above. Each runs `auth`
(`features/auth/`), which checks the Google, Spacelift and Argo CD logins at once and opens a
browser login only for each one whose check says it has expired. A check that can't reach its
service opens nothing, and the session starts whatever the checks find. With every login valid,
the checks add about a second to each start. Skipping them for a few minutes after a run that
found every login valid was considered and not taken, since a second is acceptable.
