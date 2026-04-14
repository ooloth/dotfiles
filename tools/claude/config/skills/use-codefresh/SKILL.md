---
name: use-codefresh
description: Reference for using Codefresh via the CodeFresh CLI. Use when a Codefresh CI check is failing in a recursionpharma PR, or when working with Codefresh builds.
allowed-tools: [Bash, Read]
model: haiku
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

## Troubleshooting

**Command not found:** Install with `brew install codefresh`.

**Not authorized:** Run `codefresh auth current-context` to check the active context. If missing or wrong, the user needs to re-authenticate.
