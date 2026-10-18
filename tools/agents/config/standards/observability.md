# Observability

Code is observable when the system can answer questions about its own
behaviour: whether something failed, why, what input produced it, and whether
an invariant no call site can check still holds. It is also observed when a
failure that needs a person reaches one. How those signals are emitted and
formatted is `instrumentation.md`.

## Must

**A failure mode is diagnosable from what the system records.**
Every way the code can fail can be diagnosed from its recorded output alone,
without attaching a debugger or reproducing the failure locally. What has to be
recorded is decided when the failure mode is written, because the state that
would have answered the question is gone by the time anybody asks.

## Should

**A failure that was handled still leaves a record.**
Recovering, retrying, degrading to a default or serving a cached value are all
legitimate outcomes, and each is a fact about the run that nothing else
reports. Handling an error decides what the system does about it; it does not
decide whether anybody learns it happened. `error-handling.md` covers which
layer should handle an error, and `reliability.md` covers what the process
boundary shows; this covers whether the handled case is knowable at all.

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

**A failure that needs a person reaches one.**
A deployed system raises an alert when its errors cross a threshold, when it
stops serving, and when scheduled work does not complete in its window. Each
alert goes to a channel that people read and that outlives any one person's
assignment, such as a team channel rather than one person's inbox. People move
between systems, and an alert sent to someone who has moved on reaches nobody.
A failure that is recorded but never surfaced is diagnosable only by someone
who already suspects it, so a system can satisfy every other entry in this file
and still run blind. `deployment.md` covers regressions a release introduces;
this covers everything that breaks while nobody is deploying.

**An alert has been seen to fire, end to end.**
An alert that has never fired is assumed broken, because its query, its
threshold, its routing and the channel at the end of it each fail silently.
Each alert has been triggered by a real event and seen to arrive where it is
meant to. Where triggering it in production would page someone, the proof is
split in two: the alert's condition is shown to match a test event, and a test
notification is shown to reach the channel. The split leaves the threshold and
its timing unproven, and that gap is recorded where the alert is documented.

**Each alert says what it means and links to where to look.**
An alert's text names the condition that fired it and what that condition
means for the system, and links to the logs or dashboard that show why. The
person who receives it is often not the person who wrote it, and an alert only
its author can interpret waits for its author.

## Consider

**Alerts are few enough that none gets muted.**
Each alert that fires without needing action teaches its readers to ignore the
channel, and once the channel is ignored, the alerts that matter go unread with
the rest. A new system starts with the fewest alerts that cover errors,
unavailability and missed scheduled work, and gains one only when a failure
went unnoticed without it.

## In scope

- Error paths
- Failure modes
- Quantitative claims backing a design, performance, or process decision
  (rates, latencies, costs, capacity estimates)
- Invariants that hold across processes, runs, or accumulated state rather than
  within a single call
- Alert definitions, their thresholds and their routing

## Out of scope

- Log format, log levels, field naming and telemetry placement, which belong to
  `instrumentation.md`
- Test code
- Intentional no-op error handling that is explicitly documented
