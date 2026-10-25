---
updated: 2026-10-25
update_when: the work laptop check below is run, or #127 starts
decays: slow
status: open
---

# How does a fresh Mac get uv and Python before the first script needs them?

## Why it matters

[Decision 007](../decisions/007-scripts-that-are-run-are-written-in-python.md) moves every script
that is run to Python, and
[decision 008](../decisions/008-the-repos-python-is-one-uv-project-at-the-repo-root.md) puts that
Python in one uv project at the repo root. Neither can run on a fresh Mac until uv and a Python
are installed, and setup's first step runs before either exists. The answer decides how much of
that first step has to be bash, and #127, which replaces `features/setup/setup.zsh`, cannot start
without it.

## What would settle it

**Whether a fresh work laptop can download Python with uv before gcloud is set up.** On a work
laptop the managed uv config may route that download through Artifact Registry, which needs
Application Default Credentials first. Run this on the work laptop:

```sh
cat ~/.config/uv/uv.toml
UV_PYTHON_INSTALL_DIR=$(mktemp -d) uv python install 3.10 -v
```

The first command shows whether the managed config sets `python-downloads`, a
`python-install-mirror`, or `python-preference`. The second downloads a Python into a scratch
directory without touching the installed ones. Look for which URL it downloads from and whether
it fails. A laptop that already has gcloud logged in can hide an Artifact Registry dependency, so
to see what a fresh laptop sees, run the second command again after
`gcloud auth application-default revoke`, then log back in with
`gcloud auth application-default login`.

A failure tells you which of these is in the way: the network blocks the download host, a proxy
re-signs HTTPS with a company certificate that uv does not trust without `--system-certs`, or the
managed config disables or redirects Python downloads.

## Resolves into

A decision record in `../decisions/` naming what setup's first step does before handing over to
Python, and in which language. #127 follows it.

## Source

Split on 2026-10-25 from the question that decisions 007 and 008 answered, when the maintainer
asked how much bash, if any, the first moment on a fresh machine needs before everything after it
can use tested and type-checked Python. The full findings of that question are in
[its last version](https://github.com/ooloth/dotfiles/blob/f923e2e55c6ac92cadf63f62b2e9c5829e5cf29e/docs/questions/how-should-this-repos-python-be-set-up-and-bootstrapped.md).

## Options

None written yet.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Measured (2026-10-19):* uv 0.13.2 downloads Python from `releases.astral.sh`, not from PyPI or
  the package index set in `~/.config/uv/uv.toml`. This was measured on a personal machine with no
  `uv.toml`.
- *Unverified:* whether a fresh work laptop can download Python with uv before gcloud is logged
  in. The check under **What would settle it** answers it.
- *Reasoned:* the global Python standards call for Pydantic at boundaries. A setup that has to run
  before gcloud is logged in cannot install third-party packages on a work laptop, so the code it
  runs would be limited to the standard library, with ruff, `ty` and pytest only in the dev group.
  Whether `uv run --no-dev` on a project with no runtime dependencies reaches the package index at
  all is *Unverified*.
