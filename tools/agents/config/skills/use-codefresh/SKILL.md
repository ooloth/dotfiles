---
name: use-codefresh
description: Reference for using Codefresh via the CodeFresh CLI (run from its Docker image). Use when a Codefresh CI check is failing in a recursionpharma PR, or when working with Codefresh builds.
allowed-tools: [Bash, Read]
model: haiku
effort: low
---

Consider using a subagent when you just need an answer and don't need to see the intermediate
CodeFresh responses.

## Extract Build ID from PR Status Checks

From `gh pr view <number> --json statusCheckRollup`:

- Failing checks have `"state": "FAILURE"` (StatusContext) or `"conclusion": "FAILURE"` (CheckRun)
- Build URL is in `targetUrl` (StatusContext) or `detailsUrl` (CheckRun)
- Extract the 24-char hex ID from `https://g.codefresh.io/build/{build-id}`

## Commands

```bash
# A pipeline's recent builds, newest first. The name includes the project prefix
# (bc-eng-clinical/external-siteoutreach-dev-backend); --branch and --status also filter.
# The table's times are local but 12-hour with no AM/PM, so read `created` from -o json
codefresh get builds --pipeline-name <project>/<pipeline> --limit 5

# Build metadata
codefresh get builds <build-id> -o json

# Full logs (can exceed 30k lines — use grep to find errors quickly)
codefresh logs <build-id> | grep -E -B 10 -A 20 -i "error|fail|found.*error"
```

## Log Structure

Codefresh logs are long (often 1000–3000+ lines) and front-loaded with noisy setup
output: apt package installs, Python compilation `configure` checks, mise tool
downloads. **The actual failure is almost always near the end.** Skip directly to
the tail and work backwards:

```bash
# Start at the end — most failures appear in the last ~100 lines
codefresh logs <build-id> 2>&1 | tail -100

# Then narrow with grep if needed
codefresh logs <build-id> 2>&1 | grep -E -B 5 -A 15 "FAILED|ERROR|AssertionError|raise " | tail -150
```

### Failure type heuristics

| What you see near the end | Likely cause |
|---|---|
| `FAILED tests/...` / `AssertionError` | Test failure (prek/pytest) |
| `ruff-check...Failed` / `ty check...Failed` | Lint or type error |
| `error: ...` in a Python traceback | Runtime error in a build step |
| Process exited with code 1, no clear message | Check a few hundred lines before the end |

## Starting a run

Starting a build is a side effect, so get the user's approval first and say so in the command's
description, or the auto-mode classifier blocks it. `--detach` prints the build id and returns:

```bash
codefresh run <pipeline-name-or-id> --trigger <trigger-name> -b <branch> -s <full-sha> --detach
```

A new run loads the pipeline's spec as it is now, when the spec comes from git (`specTemplate` with
`revision: trunk` in `codefresh get pipelines <name> -o json`). A restart of an old build may replay
that build's spec, so to pick up a spec change, start a new run instead of restarting.

## Troubleshooting

**Command not found:** `codefresh` is a wrapper in the dotfiles (`tools/codefresh/bin/codefresh`,
linked into `~/.local/bin` by its `link.bash`) that runs the official `codefresh/cli` Docker image.
Do not install it with Homebrew or npm. The Homebrew tap's packaged binary crashes on startup with
`Cannot find module '/snapshot/cli/...'`, and the npm package needs a git dependency that npm 12
refuses to fetch by default.

**Docker isn't running:** the wrapper says so and exits 1. Ask the user to start Docker. If they
can't, the REST API answers the same questions, but an agent in auto mode is usually blocked from
reading the token out of `~/.cfconfig`, so ask the user's approval before trying:

```bash
TOK=$(grep -E "^\s+token:" ~/.cfconfig | head -1 | sed -E "s/.*token: *'?([^']*)'?/\1/")
curl -s -H "Authorization: $TOK" "https://g.codefresh.io/api/workflow?limit=100&page=1"  # recent builds
curl -s -H "Authorization: $TOK" "https://g.codefresh.io/api/builds/<build-id>"           # one build
curl -s -H "Authorization: $TOK" "https://g.codefresh.io/api/progress/<progress-id>"      # log location
```

The build document's `progress` field is the progress id. The progress document's `location.url` is
a signed URL that returns the whole log as JSON, with one entry per step in `steps[].logs`.

**Not authorized:** Run `codefresh auth current-context` to check the active context. If missing or
wrong, the user needs to re-authenticate. The wrapper mounts `~/.cfconfig` read-only, so the user
runs `docker run --rm -it -v ~/.cfconfig:/root/.cfconfig codefresh/cli auth create-context` (no
`:ro`) or edits `~/.cfconfig` directly.
