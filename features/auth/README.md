# auth

Logs in to each work tool whose credentials have expired, so one command covers the morning's
logins. Defined only on the work laptop.

```sh
auth          # check every login, then run the browser login for each expired one
auth --check  # only report; logs in to nothing
```

On the work laptop, every Claude Code session `tools/claude/cc.bash` starts runs `auth` first,
then starts whatever the checks found. A session started with `--unattended` skips it, since nobody
is there to finish a login. With every login valid, that adds about a second, set by the slowest
check, the recursion.com one. A check that hasn't answered after 10 seconds is reported as
`couldn't check`, so a server that hangs costs at most that.

It checks these all at once, then logs in to the expired ones one at a time:

- **Google (recursion.com), with ADC:** checks with
  `gcloud auth application-default print-access-token` and logs in with
  `gcloud auth login --update-adc <account>`.
- **Google (rxrx.tech):** checks with `gcloud auth print-access-token --account=<account>` and logs
  in with `gcloud auth login --no-activate <account>`.
- **Spacelift:** checks with `spacectl whoami` and logs in with
  `spacectl profile login --method browser --endpoint https://<account>.app.spacelift.io/ <account>`.
- **Argo CD, once per server:** checks with
  `argocd account get-user-info --grpc-web --output json --server <server>` and logs in with
  `argocd login --sso --grpc-web <server>`. Each server has its own SSO and its own token, so each
  gets its own line and its own login. `argocd login` makes the server it logged in to the current
  context, so after any Argo CD login `auth` runs `argocd context <first server>`, which keeps the
  first server listed as the default that `argocd` commands without `--server` use.

Runs that start together, such as several Claude sessions opened at once, share the logins. A run
that finds a login expired takes a lock on `~/.local/state/auth/logins.lock` before logging in. If
another run holds it, such as another session's or an `auth` typed in a terminal, it prints
`⏳ Another run of auth is logging in; waiting for it...` and waits. Once it holds the lock, it
checks every expired login again at once and logs in to each unless that check finds it valid or
its tool missing, so a login another run just finished isn't opened again. A check that can't tell
still logs in, and after one login the next is checked once more, since a login can make another
valid. The system releases the lock when a run ends, even when it crashes, and Ctrl-C while waiting
stops the run as it does during a check. Runs that wait take the lock one after another, each for
one round of checks, so the last of several sessions opened together waits about one round for
each run ahead of it. A run whose logins are all valid never takes the lock.
When the lock file can't be created, the run says so and logs in without sharing. The lock is in
`login_lock.py`.

It prints `Checking logins...` and then one line per login as soon as that login's result is final,
so the lines come out in the order the checks finish and a slow check doesn't hide the others. An
expired login's line comes after its login, from the check it runs again then, or after its check
under the lock, marked `(checked again, no login run)`, when that check found it valid or its tool
missing, such as after another run's login. It exits 0 only when every login ends up valid, so
`auth && <command>` runs the command only once you're logged in.

- **The Spacelift account and the Argo CD servers** come from `PRIVATE_SPACELIFT_ACCOUNT` and
  `PRIVATE_ARGOCD_SERVERS` in `private.env` (see `private.env.example`). The servers are a
  space-separated list, default first, and a server listed twice is checked once. Without one of
  the keys, its line says so and the other logins still run, and `auth` exits 1.
- **`argocd account get-user-info` usually exits 0 even when the session has expired**, so the
  script reads its `loggedIn` field. A failure that names a revoked token (`invalid_grant`) or a
  rejected session (`code = Unauthenticated`) also counts as expired. Any other failure, such as
  an unreachable server, is reported as not checked and its login is not run, unless the run's
  first check already found it expired.
- **gcloud and spacectl exit non-zero both when a login has expired and when the network or the
  service is down**, so the script reads what they print. Only a message naming the credentials,
  such as `Reauthentication required`, `invalid_grant` or `please login first`, counts as expired.
  Any other failure is reported as not checked, so a dropped VPN opens no browser logins, except
  for one the run's first check already found expired.
- **`--method browser`** skips Spacelift's menu asking which kind of login to use, and
  **`--endpoint`** skips its prompt for the account's URL, which it asks for even when the profile
  already has one.
- **Ctrl-C during a login** stops only that login. `auth` checks it again and goes on to the next
  one, and still prints a line for every login.
- **Pomerium** is left out: `griphook` has no command that reports whether a session is still valid.
- **No packages:** the script uses only the standard library and the alias runs it with
  `uv run --offline`. Then uv never reaches the work package index, which needs the very Google
  credentials `auth` may be about to refresh.

Tests: `uv run features/auth/tests/test_auth.py`. Unlike the script, the tests need `hypothesis`,
which on the work laptop uv fetches through the work package index, so they need a valid Google
login (see `CONTRIBUTING.md`).
