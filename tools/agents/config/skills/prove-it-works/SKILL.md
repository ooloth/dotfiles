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

## Who the proof is for

A reviewer who wasn't there, doubts the change works, and will believe only what they could check
themselves. Prove each claim for that person, whether or not the target is a PR:

- **The claims:** given a design with an Observable behaviour table, its rows are the claims, in
  its words and order. Given only an approach with a property table, each binding property is a
  claim, and so is each scenario a user relies on that the change could break but no property
  names. The
  report may cite a property's number, but states each claim in words, since that is what a
  reviewer reads. Say which binding property no claim shows, and what covers it instead,
  such as a test CI runs.
- **Steps that person could run:** each claim's proof is a set of steps written the way they would
  copy them: complete commands from a fresh checkout, the setup each one needs, and what to expect.
  Run them in exactly that form, save each step's output to a file of its own, and append each
  command exactly as run to one `commands.txt` in the evidence folder, so a caller can check that
  every step it shows is one that ran. Any means may
  find the steps, but the evidence comes from running them as written.
- **A change nobody planned:** when running base against head shows behaviour that neither the
  design's Observable behaviour table nor the ticket lists, say which of two it is. A bug stops
  the work until it is fixed and run again. Behaviour the change should have goes back to the
  user, so the design can gain it through a change comment on the ticket before it is claimed.
  Either way the report names it, so it never reaches a PR as an unexplained row.
- **Steps already written:** when the target already lists verification steps, as a PR description
  or a ticket may, run those as written too, and report each one that does not hold.
- **The system, not the suite:** "the tests pass" convinces nobody who doubts the tests, so a step
  runs the system and never points at the test suite or CI.
- **Where each step runs:** a step a reviewer can run on a laptop before merging says so. One that
  only a deploy can show says which environment and when. Where no signal would show a claim, say
  what signal would, so it can be added.

## The bar

How you gather the proof is yours to decide. What you return must meet this bar:

- **Every part of the claim gets a verdict:** proven, disproven, or not observable here, with what
  would make it observable. "Not observable" comes only after the obvious alternatives (a retry,
  another model, account, host or tool) have been tried.
- **The evidence comes from the running system,** not from tests or from reading code, and covers
  every path the change can take, including its main purpose end to end.
- **A reader who wasn't there can check every observation.** Save each command's raw output as it
  runs, in a new folder from `mktemp -d`, or in the folder the caller names, such as the one
  `merge-and-verify` keeps for a merge, and name the exact artifact it observed (host, revision,
  image, token, file). Every quote in the report points to the file it came from, and matches it
  exactly. A `mktemp -d` folder is temporary and the system deletes it in time, so the report names
  the folder for the caller, and whoever posts the report carries what it quotes from each cited
  file in the post, never a local path: quoted text inline, and a screenshot or recording uploaded
  where a skill here says how, as `use-gh` does for GitHub, or described in words elsewhere,
  including Jira. On a public destination, the poster opens each image and checks it for private
  values before uploading it.
- **Before and after,** wherever a before state can be observed.
- **Every attempt is shown,** including the ones that failed or cut against the claim.
- **What an app shows is observed in the app itself,** never inferred from server or internal
  state. A claim about what a browser page, a native app such as Rex, or a terminal UI shows is
  proven by the app's own screen, its own log lines or its direct output, saved in the same folder.
- **A terminal's screen is captured as text,** with `rex capture` in Rex or `tmux capture-pane -p`
  in tmux, because text can be quoted exactly.
- **Any other window is captured on its own, never the whole screen,** with
  `uv run <this skill's folder>/scripts/capture_window.py --app <name> --out <folder>/<name>.png`,
  adding `--title` when the app has several windows, or `--window-id` with an ID a failure
  message printed, to pick an untitled window or one of several with the same title. Window titles
  can hold private information, so look up no other app's windows. The terminal it runs in needs
  macOS's Screen Recording permission, and on a work laptop `uv` fetches its `pydantic` only after
  `gcloud auth login --update-adc`, as `CONTRIBUTING.md` in the dotfiles repo describes. What a
  browser shows can instead be a screenshot or recording taken by the browser automation. Those land
  in `~/Library/Caches/playwright-mcp`, so copy each one cited into the evidence folder.
- **Each screenshot is opened and checked before it is cited:** it shows the expected window, and
  nothing secret.
- **Nothing secret appears** in the saved files or the report.
- **Nothing in a deployed environment changes** unless the user approves that specific action.

Write the report however makes the proof clearest to a reader, as long as it opens with the claim,
gives each verdict with its evidence, and ends with what could not be observed. Under each verdict,
give its steps exactly as they ran and the files holding their output, so a caller such as
`write-pr-description` can hand them to a reviewer unchanged. Return it as your
final message.
