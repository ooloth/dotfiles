# Observability

Code is observable when failures are visible, diagnosable from logs alone,
claims about its behavior are backed by measurement rather than assumption,
invariants it cannot check at a call site are checked against what it
records, and new behavior leaves a trace without obscuring the logic that
produces it.

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

**An invariant no single call site can evaluate is checked against real state.**
Some conditions only a bug can violate hold across processes, across runs, or
over accumulated state rather than within one call: every accepted item reaches
a terminal state, a queue drains, two representations that `data-integrity.md`
requires to stay in sync actually agree. Each has something that reads the real
state and reports a discrepancy — a reconciliation pass, a periodic verifier, a
comparison of two counters. Where that state is not already durable, the record
the check reads is written on purpose, because a check with nothing to read
cannot be written at all. The check reports rather than halting: the output it
disagrees with has already been produced, so there is nothing left to interrupt.
Left to tests, such an invariant is exercised only by data a test author made
up, while the obligation reads as discharged because a test names it.

**A failure's input is recoverable from what was recorded.**
Determinism makes a failure replayable in principle and the retained input is
what makes it replayable in fact. Where an input arrives as a stream, a large
payload, or a value the process consumes and discards, what is recorded at the
failure reconstructs it: the value itself, or a reference that still resolves
to it. Where the input is personal data the reference is the only available
form, because `privacy.md` rules out the value.

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
- Invariants that hold across processes, runs, or accumulated state rather than
  within a single call

## Out of scope

- Test code (no logging required)
- Intentional no-op error handling that is explicitly documented
