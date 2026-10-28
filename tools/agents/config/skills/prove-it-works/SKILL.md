---
name: prove-it-works
description: Prove or disprove a claim about the running system with recorded evidence, given one sentence naming a claim or a pointer (PR, branch, commit, endpoint or URL). TRIGGER when asked to prove a change works, to verify a claim, or when a session needs evidence of a change's effect.
argument-hint: 'A claim, or a pointer such as "#238", a commit, an endpoint or a URL'
---

Input: $ARGUMENTS

## What you are given

One sentence is enough. It is either a claim ("the study editor keeps unsaved edits in External
DEV"), a ticket's property table or Ideal state, or only a pointer: a PR, branch, commit, endpoint
or URL.

- **Given a claim,** prove that claim. Don't re-derive the change's intent, and don't ask the
  caller why they believe it.
- **Given only a pointer,** work out what to prove from what it names. For a PR, that is each
  behaviour that differs between its base and its head, read from the diff, its ticket's
  properties and its review.

Get everything else from the environment: the PR and its ticket, the diff, the repo's `CLAUDE.md`
and deploy docs for which host each environment serves and how to read what is serving there, and
the revision that served before the change. Ask the user only for what none of these hold, such
as which org when the request doesn't say and a rule says to ask, or a credential only they can
refresh. Never ask them to restate the claim in a template.

## Evidence

Plan the observations yourself. Each one comes from the running system, not from tests or from
reading code.

- **Cover every path the change can take,** not only the one the claim names. Each input, branch
  and failure a user could reach, including the change's main purpose end to end, becomes a
  finding or an `unobserved` entry.
- **"Not observable" comes last.** When an observation fails for a reason outside the change, such
  as an auth error or a blocked request, try the obvious alternatives first (a retry, another
  model, account, host or tool), record each attempt, and only then call it not observable.

Every observation goes through the recorder, so its command and raw output are written as they ran
and never retyped. Start one run per proof, and pass its folder to every later call:

```sh
uv run <skill-base-dir>/scripts/record.py start --repo <owner>/<repo> --commit <sha>
uv run <skill-base-dir>/scripts/record.py run <run-dir> --artifact "<what this observes>" \
  [--side before|after] [--timeout <seconds>] -- '<command>'
uv run <skill-base-dir>/scripts/record.py attach <run-dir> <file> --artifact "<what it shows>" \
  [--side before|after]
```

- **Name the exact artifact** in `--artifact`: the host, revision, image tag, token or file the
  command reads. An observation of a neighbouring artifact, such as one environment in place of
  another, is not evidence.
- **Observe before and after** wherever a before state can be observed, and mark each with
  `--side`.
- **Change nothing in a deployed environment** unless the user approves that specific action.
  Reading is always fine.
- **Browser evidence** comes from the `browser-automation-agent`, signed in only to the app under
  test. Have it take each screenshot without a filename, so it lands in Playwright's own output
  folder rather than the repo, then `attach` the path it reports.
- **A failed attempt stays recorded.** Don't rerun a command until it gives the answer you want and
  cite only that run. The report lists every observation no finding cites.

## Report

Write a draft as JSON in a `mktemp -d` folder. It holds the claim, then one finding per part of the
claim, each `proven`, `disproven` or `not_observable`:

```json
{"claim": "...",
 "findings": [
   {"statement": "...", "verdict": "proven", "why": "...",
    "cites": [{"observation": "o2", "lines": [3, 5]}]},
   {"statement": "...", "verdict": "not_observable", "why": "...",
    "needs": "what would make it observable"}],
 "unobserved": ["anything you could not observe, and why"]}
```

A proven or disproven finding cites the observations that show it. Cite the lines that matter,
since the report quotes exactly those lines from the stored output. What you couldn't observe is
listed, never inferred. Then render it:

```sh
uv run <skill-base-dir>/scripts/record.py report <run-dir> <draft.json>
```

If it refuses the draft, fix the draft and render it again. Return the rendered report as your
final message, unchanged. Its shape is fixed (claim, findings with quoted evidence, uncited
observations, what was not observed) so a calling session can read it directly. It is also saved
as `report.md` in the run folder.
