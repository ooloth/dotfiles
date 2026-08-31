# Observability

Code is observable when failures are visible, diagnosable from logs alone,
claims about its behavior are backed by measurement rather than assumption,
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

**A load-bearing claim about behavior is measured, not assumed.**
A rate, a latency, a frequency, or a cost that a decision depends on is
checked against real measurement wherever one is feasible to take. Where
nothing currently measures it, that absence is closed by adding the
instrumentation rather than carried forward as an assumption — an
assumption that stands in for a measurement long enough stops being
flagged as one.

**Log output is structured.**
Logs use a consistent machine-parseable format — JSON or key=value — with
well-defined field names. Free-form prose strings are not the output format
for production logging. Structured logs can be queried, aggregated, and
alerted on; unstructured logs cannot.

**Log messages are actionable.**
Logs include enough context to act on — relevant IDs, states, and values.
Log levels are appropriate: errors for failures, warnings for degraded states,
info for significant events, debug for diagnostic detail.

**Observability doesn't obscure business logic.**
Telemetry calls are isolated from the code they instrument. The primary intent
of the surrounding code remains clear after instrumentation is added.

## In scope

- Error paths
- New behavior entry points
- Resource allocation and cleanup sites
- Quantitative claims backing a design, performance, or process decision
  (rates, latencies, costs, capacity estimates)

## Out of scope

- Test code (no logging required)
- Intentional no-op error handling that is explicitly documented
