---
name: prove-it-works
description: Prove or disprove a claim about the running system, given one sentence naming a claim or a pointer (PR, branch, commit, endpoint or URL). TRIGGER when asked to prove a change works, to verify a claim, or when a session needs evidence of a change's effect.
argument-hint: 'A claim, or a pointer such as "#238", a commit, an endpoint or a URL'
---

Input: $ARGUMENTS

## What you are given

One sentence is enough. It is either a claim, a ticket's property table or Ideal state, or only a
pointer: a PR, branch, commit, endpoint or URL. Given a claim, prove that claim; don't re-derive the
change's intent. Given only a pointer, work out what to prove from what it names. For a PR, that is
each behaviour that differs between its base and its head.

Get everything else from the environment: the PR and its ticket, the diff, the repo's docs for
which host each environment serves and how to read what is serving there. Ask the user only for
what none of these hold, and never ask them to restate the claim in a template.

## The bar

How you gather the proof is yours to decide. What you return must meet this bar:

- **Every part of the claim gets a verdict:** proven, disproven, or not observable here, with what
  would make it observable. "Not observable" comes only after the obvious alternatives (a retry,
  another model, account, host or tool) have been tried.
- **The evidence comes from the running system,** not from tests or from reading code, and covers
  every path the change can take, including its main purpose end to end.
- **A reader who wasn't there can check every observation.** Save each command's raw output as it
  runs, in a new folder under `~/Repos/agents/prove-it-works/<owner>-<repo>/<commit>/`, and name the
  exact artifact it observed (host, revision, image, token, file). Every quote in the report points
  to the file it came from, and matches it exactly.
- **Before and after,** wherever a before state can be observed.
- **Every attempt is shown,** including the ones that failed or cut against the claim.
- **What an app shows is observed in the app itself,** never inferred from server or internal
  state. A claim about what a browser page, a native app such as Rex, or a terminal UI shows is
  proven by the app's own screen, its own log lines or its direct output, saved in the same folder.
- **A terminal's screen is captured as text,** with `rex capture` in Rex or `tmux capture-pane -p`
  in tmux, because text can be quoted exactly.
- **Any other window is captured on its own, never the whole screen,** with
  `uv run <this skill's folder>/scripts/capture_window.py --app <name> --out <folder>/<name>.png`,
  adding `--title` when the app has several windows. Window titles can hold private information,
  so look up no other app's windows. What a browser shows can instead be a screenshot or recording
  taken by the browser automation.
- **Each screenshot is opened and checked before it is cited:** it shows the expected window, and
  nothing secret.
- **Nothing secret appears** in the saved files or the report.
- **Nothing in a deployed environment changes** unless the user approves that specific action.

Write the report however makes the proof clearest to a reader, as long as it opens with the claim,
gives each verdict with its evidence, and ends with what could not be observed. Return it as your
final message.
