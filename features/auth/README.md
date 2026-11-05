# auth

Logs in to each work tool whose credentials have expired, so one command covers the morning's
logins. Defined only on the work laptop.

```sh
auth          # check every login, then run the browser login for each expired one
auth --check  # only report; logs in to nothing
```

It checks these, all at once, and logs in to the expired ones one at a time:

| Login | Check | Login |
| --- | --- | --- |
| Google (recursion.com), with ADC | `gcloud auth application-default print-access-token` | `gcloud auth login --quiet --update-adc <account>` |
| Google (rxrx.tech) | `gcloud auth print-access-token --account=<account>` | `gcloud auth login --quiet --no-activate <account>` |
| Spacelift | `spacectl whoami` | `spacectl profile login --method browser recursion` |
| Argo CD | `argocd account get-user-info --output json` | `argocd login --sso --grpc-web <server>` |

After each login it checks again, and the summary reports what that check found. It exits 0 only
when every login ends up valid, so `auth && <command>` runs the command only once you're logged in.

- **The Argo CD server** comes from `PRIVATE_ARGOCD_SERVER` in `private.env` (see
  `private.env.example`). Without it, the Argo CD line says so and the other logins still run.
- **`argocd account get-user-info` exits 0 even when the session has expired**, so the script reads
  its `loggedIn` field. A check that fails for another reason, such as an unreachable server, is
  reported as not checked and its login is not run.
- **`--quiet`** answers the Y/n prompt gcloud shows after the browser step with its default, and
  **`--method browser`** skips Spacelift's menu asking which kind of login to use.
- **Pomerium** is left out: `griphook` has no command that reports whether a session is still valid.
- **No packages:** the script uses only the standard library and the alias runs it with
  `uv run --offline`. Then uv never reaches the work package index, which needs the very Google
  credentials `auth` may be about to refresh.

Tests: `uv run features/auth/tests/test_auth.py`.
