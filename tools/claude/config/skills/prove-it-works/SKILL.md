---
name: prove-it-works
description: Survey observable paths, run the real system, capture evidence, and surface gaps. TRIGGER when asked to prove a change works or write a QA plan.
argument-hint: 'Scope to check (e.g. "current branch", "the /login endpoint", "the retry logic in src/queue.ts") [optional]'
---

Scope: $ARGUMENTS (if empty, assume the current change).

## Step 1 — Survey: what paths exist?

Before running anything, produce a short report:

- **Entry points**: how can this code be reached? (CLI flag, HTTP endpoint, import, event, etc.)
- **Branches**: what distinct paths does execution take? (happy path, error case, edge inputs, etc.)
- **Observable outputs**: what does the system emit that you can check? (stdout, log lines, HTTP response, file on disk, UI state, exit code, etc.)
- **Gaps**: what paths exist that you cannot observe directly, and why?

This is a planning artifact, not prose — use a list.

## Step 2 — Run: execute against the real system

Pick the real entry point. Real inputs. Real outputs. Not a test runner.

If you find yourself reaching for a test file, stop and ask: how would I observe this behaviour
if I had no test suite at all? That's the question to answer.

Cover every branch from Step 1 that you can reach. For each run, record:
- What you ran (exact command, request, or interaction)
- What you observed (stdout, response, file content, UI — not "it seemed fine")

❌ "The tests pass and the logic looks correct."
✅ "I ran `npm run dev`, navigated to /settings, toggled the feature, and saw the config update in the network response."

## Step 3 — Gap audit

After running, answer two questions:

1. **What remains unobserved?** List any paths from Step 1 you couldn't reach, and why (missing fixture, needs live infra, too slow to set up locally, etc.)
2. **What tests are missing?** Focus on integration tests and black-box tests that run the real system and assert from outside — not unit tests that mock internals. A good integration test here would reproduce what you just ran manually. If a gap from #1 could be closed by adding such a test, say so explicitly.

Don't let this section distract from Steps 1–2. The primary goal is live evidence, not test design. Surface the gap, name the test type, move on.

## Step 4 — Decide (internal, do not output yet)

Before writing the report, decide what you'll recommend. Ask yourself:

- Are any unobserved paths blockers to shipping?
- Which missing tests from Step 3 are highest priority?
- Is anything only verifiable in staging/prod — and if so, what should the user watch for?

Produce a private prioritized list (3–5 bullets). Use these categories:

- **Ship it** — all critical paths observed, no blockers
- **Fix before shipping** — specific gap is a blocker; name it
- **Add tests** — specific integration tests worth writing; name them
- **Needs live infra** — name what to watch for in staging/prod

Hold this list. Output nothing yet.

## Step 5 — Report

Now output the summary table followed immediately by the recommendations from Step 4:

| Path | Observed? | Evidence | Notes |
|------|-----------|----------|-------|
| Happy path | ✅ | `npm run dev` → navigated to /settings → saw config update in network response | |
| Invalid input | ✅ | `curl -X POST /api/foo -d '{}'` → 400 response with expected error body | |
| DB unreachable | ❌ | Can't simulate locally without stopping the DB container | Missing integration test |

**Recommended next steps:**

- Add integration test: ...
- Ship it / Fix X before shipping / Watch for Y in staging

> What would you like to do?
