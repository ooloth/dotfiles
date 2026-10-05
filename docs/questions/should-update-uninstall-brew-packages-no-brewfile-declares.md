---
updated: 2026-10-03
update_when: a laptop is audited, the cleanup dry run runs cleanly, or `u` gains a cleanup step
decays: fast
status: open
---

# Should `u` uninstall brew packages that no Brewfile declares?

## Why it matters

Deleting a `tools/{name}/` folder leaves its formula or cask installed, because `u` only installs
and upgrades. Each laptop therefore drifts from what the repo declares, and nothing reports the
drift. Turning on automatic removal without checking first has the opposite risk: it uninstalls
something a laptop depends on but no Brewfile declares, such as a package installed by hand or a
dependency another tool calls at runtime. That breakage would show up later, far from the
cleanup that caused it, and would be hard to trace back.

## What would settle it

An audit of each laptop (home and work), listing every installed package that no Brewfile
declares and recording, for each one, whether it should be declared, uninstalled, or kept
deliberately undeclared. The audit needs `brew bundle cleanup` (without `--force`, which only
reports) to run cleanly first. On the work laptop it currently errors before listing anything
(see Findings).

## Resolves into

A decision record in `../decisions/` on whether `tools/homebrew/update.bash` removes undeclared
packages, reports them, or does neither. If it removes them, the "Deprecating a Tool" steps in
`tools/README.md` and step 6 of `.claude/skills/add-tool/SKILL.md` stop needing a manual
`brew uninstall`.

## Source

Raised on 2026-10-01 while adding `tools/prek/`. The approach relied on deleting a tool folder
being enough to remove a brew tool, as `tools/README.md` claimed. That claim was false, and the
README now says to run `brew uninstall`. The maintainer said they want to audit each laptop for
things that would disappear but shouldn't before adding automatic cleanup.

## Options

- **Do nothing (current).** Removing a tool takes a documented manual `brew uninstall`. Nothing
  is ever removed by surprise. The cost is invisible drift, plus every removal depending on
  someone remembering the step.
- **Report only.** `u` runs `brew bundle cleanup` without `--force` and prints what is installed
  but undeclared. It never removes anything, but it makes drift visible on every run. The cost is
  noise until each laptop's undeclared list is resolved, and the dry run has to stop erroring
  first.
- **Remove automatically.** `u` runs `brew bundle cleanup --force`. The Brewfiles become the
  complete truth, and deleting a folder is enough. The cost is that anything installed by hand is
  deleted on the next `u`. That is only safe once both audits are done.
- **Report now, remove after the audits.** This is the order the maintainer described.

## Findings

Nothing here is settled until it graduates into a decision record.

- *Sourced:* `tools/homebrew/update.bash` runs `generate-brewfile.bash`, `brew update`,
  `brew bundle`, `brew upgrade`, `brew autoremove` and `brew cleanup`. None of these uninstalls a
  package that has dropped out of `Brewfile.generated`. `brew autoremove` only removes
  dependencies that nothing installed needs any more.
- *Sourced:* `features/setup/setup.zsh` installs Homebrew but never runs `brew bundle`. On a new
  machine, Brewfile packages first arrive on the first `u`.
- *Measured (2026-10-01, work laptop):* `brew bundle cleanup
  --file=tools/homebrew/Brewfile.generated`
  printed a circular-dependency warning for `libtiff` and `webp`, then exited with
  `Error: No available formula with the name "spacelift-io/spacelift/spacectl"` without listing
  anything.
- *Measured (2026-10-03, Air):* `postgresql@14` was installed on request on 2026-02-27 and stayed
  linked after `tools/postgresql/Brewfile`'s `postgresql` alias moved to `postgresql@18`. `brew
  bundle` installed @18 but could not link it ("postgresql@18 was installed but not linked because
  postgresql@14 is already linked"), so `psql` ran version 14 with nothing reporting it. No
  Brewfile declared @14. It was unlinked and uninstalled by hand. The same thing will happen at the
  next major version, because a versioned formula's link is not moved when the alias moves.
- *Not yet measured:* the home laptop's dry-run output.
