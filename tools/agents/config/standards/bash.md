# Bash

Bash-specific standards for shell scripts. Read alongside the general reference files.

Which bash version a repo targets, and whether a given job belongs in bash at all, are decisions
each repo records for itself. These standards hold whatever it decides.

## Must

**A script runs under bash, and says so in its shebang.**
`#!/usr/bin/env bash` on the first line means the script gets bash's word splitting, arrays and
`read` options whatever shell started it. A script without one runs under the caller's shell, and
a command written for bash then behaves differently under zsh: an unquoted `$var` stays one word,
`read -a` is an error, and arrays start at 1, often without any message.

**A script passes `shellcheck`.**
`shellcheck` catches unquoted expansions, unchecked `cd`, and the other mistakes that make a shell
script do something other than what it says. Each inline disable names the rule and the reason
beside it, so the exception is visible in review rather than silent.

**The bash version a script needs is known, and an older bash fails loudly.**
Features differ across versions, and some gaps fail silently: under bash 3.2, `$'\ue725'`
prints the six characters `\ue725` rather than the glyph, and nothing reports an error. So
either the script works under the oldest bash it can meet, or it checks `BASH_VERSINFO` first and
exits with a message naming the version it needs. Wrong output under an older bash is never
acceptable.

## Should

**A script stops at the first failure: `set -euo pipefail`.**
Without `-e` a failed step is followed by the next one as if it had worked; without `-u` a
misspelled variable expands to nothing; without `pipefail` a failure early in a pipeline is hidden
by the success of the last command. The exception is a script whose job is to run every step and
report all the failures together, such as a check runner. It uses `set -uo pipefail`, collects the
failures, and exits non-zero at the end if there were any.

**A script finds its own files from its own location, and keeps paths it points other things at
separate.**
The files a script sources, reads and writes are found from where the script is,
`$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)`, so a copy, a worktree or a test fixture acts on
itself. A fixed path or an inherited variable instead makes a copy silently act on a different
checkout, and every test has to fake the fixed location to run at all. A path the script points
something else at, such as where symlinks in `$HOME` should lead, is a different thing: it names a
deliberate, stable destination, so it is a named constant of its own, and the script refuses to
use any other location for it unless told to explicitly.

**Temporary files come from `mktemp -d`.**
A fixed path such as `/tmp/out.txt` is shared by every copy of the script running at once, so one
run can read or overwrite another's file. A new directory from `mktemp -d` each run, removed when
the script is done, keeps runs apart.

## Consider

**A script that grows data structures or real logic is written in another language.**
Bash has no types, no structured data beyond flat arrays, and error handling that depends on
flags. A script that parses JSON, keeps state across steps, or needs tests for its logic is
usually clearer and safer in a language with those things, while bash stays the glue that calls
other programs.

## In scope

- `.sh` and `.bash` files, and executable files whose shebang names bash

## Out of scope

- Interactive shell configuration, such as `.zshrc` and `.bashrc`
- What `shellcheck` already enforces, which it checks every time
