---
name: CLI design invariants
description: Invariants for command-line interface design; load when the changed files include a CLI binary or command-line interface
type: reference
---

# CLI Design

A CLI is well-designed when every operation is discoverable, error messages tell the
user what to do next, and the interface is stable enough that scripts built on it
don't break unexpectedly.

## Must

**Every command and flag has help text.**
`--help` produces a meaningful description for every command, subcommand, and flag.
"No description" is not acceptable for public interfaces. Help text explains what the
command does, not how it is implemented.

**Errors go to stderr; output goes to stdout.**
Error messages and diagnostic output use stderr. Machine-readable output and primary
content use stdout. This allows piping stdout while still seeing errors.

**Exit codes are meaningful.**
Zero means success. Non-zero means failure. Scripts can rely on exit codes to detect
failures without parsing output.

## Should

**Breaking changes to the CLI interface are explicit.**
Removing a flag, renaming a subcommand, or changing output format is a breaking change.
These are versioned, communicated, and not done casually. Silent breakage of scripts
is not acceptable.

**Flags compose; they don't override each other silently.**
Flags that conflict produce a clear error, not silent preference of one over the other.
Composable flags that combine predictably are preferred over flags with hidden interactions.

**Output format is consistent across subcommands.**
Similar operations produce structurally similar output. A user who learns one subcommand
can predict what another looks like. Inconsistency forces users to re-learn.

**Error messages tell the user what to do next.**
An error that only describes the failure is half-useful. Errors include: what went wrong,
why, and a concrete next step or suggestion.

## Consider

**Long-running operations report progress.**
Operations that take more than a second give the user feedback — a progress bar, spinner,
or log lines. Silent hangs are indistinguishable from failures.

**Destructive operations support `--dry-run`.**
Commands that write, delete, or send data support a `--dry-run` flag showing what would
happen without doing it. This reduces the cost of mistakes.

**Subcommand naming is big-endian.**
When subcommands have qualifiers, the concept leads: `issue create` rather than
`create issue`. Related subcommands sort together and read as a hierarchy.

## When scanning

**Surfaces:** CLI entry points and command definitions; flag and subcommand declarations; help text strings; error message output sites; exit code handling.

**False positives to skip:** internal-only commands not exposed to end users; test harness CLI utilities.
