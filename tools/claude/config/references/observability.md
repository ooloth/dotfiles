# Observability

Code is observable when failures are visible, diagnosable from logs alone,
and new behavior leaves a trace without obscuring the logic that produces it.

## Must

**Errors are surfaced, not swallowed.**
Every error path is either handled explicitly or propagated to a layer that
will log or report it. Silent failure — catching an error and doing nothing —
does not exist.

**New behavior is observable.**
Code that introduces new operations, decisions, or failure modes has
corresponding log output. If this code fails in production, the failure is
diagnosable from logs alone.

## Should

**Log messages are actionable.**
Logs include enough context to act on — relevant IDs, states, and values.
Log levels are appropriate: errors for failures, warnings for degraded states,
info for significant events, debug for diagnostic detail.

**Observability doesn't obscure business logic.**
Telemetry calls are isolated from the code they instrument. The primary intent
of the surrounding code remains clear after instrumentation is added.

## Consider

**Resource handles are closed.**
Connections, file handles, and other resources are released after use.
Long-lived processes don't accumulate open handles.
