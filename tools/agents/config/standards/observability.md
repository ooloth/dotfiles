# Observability

Code is observable when the system can answer questions about its own
behaviour: whether something failed, why, what input produced it, and whether
an invariant no call site can check still holds. How those signals are emitted
and formatted is `instrumentation.md`.

## Must

**Errors are surfaced, not swallowed.**
Every error path is either handled explicitly or propagated to a layer that
will log or report it. Silent failure — catching an error and doing nothing —
does not exist.

**A new failure mode is diagnosable from what the system records.**
Code that introduces a way to fail can be diagnosed from its recorded output
alone, without attaching a debugger or reproducing the failure locally. What
has to be recorded for that to hold is settled when the failure mode is
introduced, because the state that would have answered the question is gone by
the time anybody asks.

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

## In scope

- Error paths
- New failure modes
- Quantitative claims backing a design, performance, or process decision
  (rates, latencies, costs, capacity estimates)
- Invariants that hold across processes, runs, or accumulated state rather than
  within a single call

## Out of scope

- Log format, log levels, field naming and telemetry placement, which belong to
  `instrumentation.md`
- Test code
- Intentional no-op error handling that is explicitly documented
