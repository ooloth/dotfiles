---
updated: 2026-10-22
update_when: a script breaks under one version, or the language question is answered
decays: slow
status: open
---

# Which bash version must this repo's scripts support?

## Why it matters

Every script starts with `#!/usr/bin/env bash`, so it runs under whichever bash comes first on
`PATH`. On this Mac that is Homebrew's bash 5 at `/opt/homebrew/bin/bash`. Without Homebrew on
`PATH` it is macOS's `/bin/bash` 3.2: on a fresh Mac before Homebrew is installed, and in anything
started with a minimal `PATH`, such as a launchd job.

Bash 3.2 lacks features bash 5 has, and some of the gaps fail silently. `$'\ue725'` prints the
six characters `\ue725` in 3.2 instead of the glyph, and nothing reports an error. A script
written and checked under bash 5 can then print wrong output for a user whose `PATH` differs.
Nothing in the repo says which version is the target, so each script picks one by accident, and
fixing them gets more expensive with every script added.

## What would settle it

Whether anything besides first-time setup must run before Homebrew is installed. Setup does, so
those scripts need 3.2 whatever the answer is. The question is whether the rest of the repo also
promises 3.2 or promises bash 5 with an exception for setup.

CI runs bash 3.2 (see Findings), so it already fails on any 3.2 incompatibility the tests reach.
The local `check` runs Homebrew's bash 5, so it is the one place that hides them.

The answer to `which-language-should-this-repos-scripts-use.md` changes how much code this
covers. If scripts move to Python, only the bootstrap and anything left in bash remain.

## Resolves into

A decision record in `../decisions/` naming the supported bash version, and the check that keeps
scripts to it: the local `check` running tests under `/bin/bash`, or a version guard at the top
of each script.

## Source

Raised on 2026-10-22 while adding a Nerd Font icon to `tools/claude/config/statusline.sh`. The
first version wrote the glyph as `$'\ue725'`, which worked under Homebrew's bash and printed the
escape as text under `/bin/bash`. It was caught by running the script under both by hand, not by
the local `check`. The script now writes the glyph's UTF-8 bytes, `$'\xee\x9c\xa5'`, which both
versions handle.

## Options

- **Bash 3.2 everywhere.** Every script works on any Mac, including before Homebrew. CI catches
  incompatibilities if it runs 3.2. The local `check` would run the tests with `bash` pointing at
  `/bin/bash`, so local and CI agree. The cost is giving up bash 4 and 5 features such as
  `mapfile`, associative arrays and `${var,,}`, and rewriting the two scripts that use `mapfile`.
- **Bash 5, with 3.2 only for setup.** Scripts can use newer features, and each one exits with a
  clear message under an older bash instead of printing wrong output. CI would install bash with
  Homebrew. The cost is two targets to keep apart, and a launchd job or a minimal `PATH` would hit
  the version guard.

## Findings

Nothing here is settled until it moves into a decision record.

- *Sourced:* GitHub's runner-images README maps `macos-latest` to macOS 26 Arm64, and that image's
  software list shows `Bash 3.2.57(1)-release`, with no Homebrew bash. Read on 2026-10-22.
- *Measured:* CI runs `/bin/bash`, `GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)`,
  printed by the `Show bash version` step in run 39731021324 on 2026-10-22. This confirms the
  comment at `scripts/checks/tests.bash:18`.
- *Measured:* `tools/homebrew/generate-brewfile.bash:8` and `tools/homebrew/update.bash:18` use
  `mapfile`, which bash 3.2 does not have.
- *Reasoned:* those two work under `u` because Homebrew's bash comes first on this Mac's `PATH`.
  CI runs 3.2 and passes, so no CI test runs those lines.
- *Measured:* `/bin/bash -c "printf %s \$'\\ue725'"` printed `\ue725` on this Mac on 2026-10-22.
