---
updated: 2026-10-25
update_when: the first script is ported to Python
decays: slow
status: open
---

# How does unported bash call the repo's Python?

## Why it matters

[Decision 007](../decisions/007-scripts-that-are-run-are-written-in-python.md) moves scripts that
are run to Python over time, so for a long while both languages run and bash needs code that has
already moved. About 90 files source `tools/bash/utils.bash`, and Python cannot source bash, so a
helper ported to Python is out of reach of every bash script still using it. Each sub-issue of the
port would otherwise invent its own way across.

## What would settle it

A stated way for bash to reach the Python code that the first ported category can follow, tried
on that category before the rest copy it.

## Resolves into

A decision record in `../decisions/` naming how bash calls the repo's Python during the port.

## Source

Split on 2026-10-25 from the question that decisions 007 and 008 answered. The full findings of
that question are in
[its last version](https://github.com/ooloth/dotfiles/blob/f923e2e55c6ac92cadf63f62b2e9c5829e5cf29e/docs/questions/how-should-this-repos-python-be-set-up-and-bootstrapped.md).

## Options

- **Bash calls the package's command-line entry point.** Named in the original question as an
  example. Its strongest case and its cost are not written yet.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Sourced:* of the 25 `update.bash` files under `tools/`, counting the `@new` template, 4 call
  `update_and_symlink` (neovim, node, uv and `@new`). The other 21 run their own commands. The
  archived `tools/@archive/television/update.bash` calls it too.
- *Measured (2026-10-19):* bash tests of `update_and_symlink` need a fake `HOME`, because
  `tools/bash/utils.bash` overwrites `DOTFILES` (which `tools/agents/config/standards/bash.md`
  says a script should not rely on).
