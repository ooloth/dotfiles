---
name: use-codefresh
description: Reference for using Codefresh via the CodeFresh CLI. Use when a Codefresh CI check is failing in a recursionpharma PR, or when working with Codefresh builds.
allowed-tools: [Bash, Read]
model: haiku
effort: low
---

Consider using a subagent when you just need an answer and don't need to see the intermediate CodeFresh responses.

## Extract Build ID from PR Status Checks

From `gh pr view <number> --json statusCheckRollup`:

- Failing checks have `"state": "FAILURE"` (StatusContext) or `"conclusion": "FAILURE"` (CheckRun)
- Build URL is in `targetUrl` (StatusContext) or `detailsUrl` (CheckRun)
- Extract the 24-char hex ID from `https://g.codefresh.io/build/{build-id}`

## Commands

```bash
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

## Troubleshooting

**Command not found:** Install with `brew install codefresh`.

**Not authorized:** Run `codefresh auth current-context` to check the active context. If missing or wrong, the user needs to re-authenticate.
