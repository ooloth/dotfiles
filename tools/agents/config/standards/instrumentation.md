# Instrumentation

Instrumentation is sound when the signals a system emits can be read and
queried by somebody who was not there, and when adding them leaves the logic
that produces them as clear as it was. What has to be knowable in the first
place is `observability.md`.

## Must

**A code path that runs leaves a trace.**
Operations, decisions and failure modes each emit output covering them, and
that output is added in the same change as the path it covers. A code path that
runs and says nothing is indistinguishable from one that never ran.

## Should

**Log output is structured.**
Logs use a consistent machine-parseable format — JSON or key=value — with
well-defined field names. Free-form prose strings are not the output format
for production logging. Structured logs can be queried, aggregated, and
alerted on; unstructured logs cannot.

**Log messages are actionable.**
Logs include enough context to act on — relevant IDs, states, and values.
Log levels are appropriate: errors for failures, warnings for degraded states,
info for significant events, debug for diagnostic detail.

**Instrumentation doesn't obscure business logic.**
Telemetry calls are isolated from the code they instrument. The primary intent
of the surrounding code remains clear after instrumentation is added.

## In scope

- Logging, metric and trace call sites
- Operation, decision and failure-mode sites
- Resource allocation and cleanup sites

## Out of scope

- What has to be recorded and why, which belongs to `observability.md`
- Test code (no logging required)
- Intentional no-op error handling that is explicitly documented
