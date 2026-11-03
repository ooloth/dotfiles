---
updated: 2026-11-02
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

**Whether a fresh work laptop can download Python with uv before gcloud is set up.** The work
laptop's managed uv config sets no Python download settings (see Findings), so what could still be
in the way is the network blocking the download host, or a proxy that re-signs HTTPS with a company
certificate uv does not trust without `--system-certs`. Run this on the work laptop:

```sh
UV_PYTHON_INSTALL_DIR=$(mktemp -d) uv python install 3.10 -v
```

It downloads a Python into a scratch directory without touching the installed ones. Look for which
URL it downloads from and whether it fails. To see what a laptop before gcloud login sees without
logging out, run it with gcloud's credentials hidden from uv, as the
[start command question](what-command-starts-the-repos-python.md)'s 2026-11-02 findings did:
`CLOUDSDK_CONFIG` set to an empty directory and `GOOGLE_APPLICATION_CREDENTIALS` to a missing file.

Whether setup can also install third-party packages before login depends on the start command
question's lock option: a lock made against PyPI allows it, and committing no lock does not (see
Findings).

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
- *Reasoned:* the global Python standards call for Pydantic at boundaries. A setup that runs before
  gcloud is logged in can still install third-party packages on a work laptop from a lock made
  against PyPI, because installing from that lock sends nothing to the managed index (the
  2026-11-02 *Measured* finding below) and the maintainer allows this repo's public packages from
  PyPI there (see the start command question). Under the start command question's option that
  commits no `uv.lock`, the work laptop locks against its managed index instead, and the code setup
  runs is limited to the standard library, with ruff, `ty` and pytest only in the dev group.
- *Measured (2026-10-29):* with uv 0.13.5 on a personal machine, `uv run --frozen --no-dev` on a
  project with no runtime dependencies and no `.venv` started a module with `UV_NO_CACHE=1` and
  `UV_DEFAULT_INDEX` set to an unreachable host. This held for a packaged project built with
  `uv_build` and for one with `package = false`. Beyond an installed Python, it needed nothing
  from the network.
- *Sourced (2026-11-02):* the work laptop's managed `~/.config/uv/uv.toml` sets none of
  `python-downloads`, `python-install-mirror` or `python-preference`, and no `UV_*` variable or
  system-level uv config is set. It names one package index. Its effect on PyPI downloads is in the
  [start command question](what-command-starts-the-repos-python.md)'s 2026-11-02 findings.
- *Measured (2026-11-02):* on the work laptop with uv 0.13.6 and its managed config active,
  `UV_NO_CACHE=1 uv run --frozen -v` on a lock made against PyPI for `six==1.17.0` fetched the
  wheel from `files.pythonhosted.org`, and its log, which names each URL fetched, named no
  `pkg.dev` host. This held with gcloud logged in, and with gcloud's credentials hidden from uv,
  under which an install through the managed index failed with `Incomplete credentials`. The
  [start command question](what-command-starts-the-repos-python.md)'s 2026-11-02 findings have the
  details.
