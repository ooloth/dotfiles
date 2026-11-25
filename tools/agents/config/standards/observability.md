# Observability

Observability belongs to safety: a failure nobody learns of keeps doing harm until somebody happens
to notice it, and a failure nobody can explain is fixed by guessing. How signals are emitted and
formatted is `instrumentation.md`; this file covers what has to be knowable, for how long, and who
has to learn it. At its maximum:

- **Safety:** every failure leaves a record that explains it, including one the code recovered from
  and one no single call site can see, and every failure that needs a person reaches one who can
  act. Nothing the system reports is false: an alert fires while its condition holds and stops once
  it passes, and silence means the system is healthy, because a system that stops reporting raises
  an alert of its own.
- **Performance:** a person learns of a failure as soon as the system can tell it apart from normal
  behaviour, and diagnoses it from the record alone, with no debugger, reproduction or second
  deploy. Recording adds nothing a user notices to the path it observes.
- **Experience:** the person an alert reaches learns from the alert alone what broke, what it means
  and where to look, and alerts are rare enough that each one is read. A decision about the system
  rests on figures read from the system rather than recalled.

## Must

**A failure mode is diagnosable from what the system records.**
Every way the code can fail can be diagnosed from its recorded output alone, without attaching a
debugger or reproducing the failure locally. A failure here is a unit of work, such as a request, a
message or a job run, that ends without doing what it was for, whether or not the code caught an
error on the way, so a caught error that leaves a wrong or missing result is one. A fault the code
recovered from, so that the work still did what it was for, falls under the Should on recovered
faults below. The record meets this claim when what the code writes at the failure says what failed,
on which item, such as a request or record id, at which point in the code, and the error and state
that explain why. Keeping the failure's input so it can be run again, and keeping the record until
someone reads it, are the Shoulds on inputs and on retention below. The record a failure mode needs
is added in the same change as the code that can fail that way, because the state that would have
answered the question is gone by the time anybody asks.

## Should

**A fault the code recovered from still leaves a record.**
A recovery, such as a retry that succeeded, a default served in place of a missing value or a cached
value served in place of a fresh one, is a legitimate outcome when the run still does what it was
for, and it is a fact about the run that nothing else reports. What the run was for is what the code
says it promises: a fallback its stated behaviour allows is a recovery, and one that hands the
caller a result its stated behaviour rules out is a failure under the Must. A comment explaining why
a fallback is acceptable is not a reason for it to leave no record. Handling an error decides what
the system does about it, and leaves open whether anybody learns it happened. Without a record, a
dependency that now fails every first attempt, or a fallback that now serves every request, looks
like a healthy system until the last retry fails. `error-handling.md` covers which layer handles an
error, and `reliability.md` covers what a failure shows at the process boundary; this covers whether
a recovered fault is knowable at all.

**A rate, latency, frequency or cost that a decision rests on is measured on the system it
describes.**
A figure that a design, performance or process decision depends on is checked against a measurement
of the running system, and the decision's record cites that measurement so a reader can check it,
such as by the query, dashboard or run that produced it and the date it was read. Where nothing
measures it yet, the instrumentation that would is added, rather than the figure being carried
forward as an assumption. An assumed figure reads exactly like a measured one, so the longer it
stands, the more decisions are built on it. The one exception is the one `decision-making.md` allows
for observing a decision's inputs: a measurement that would cost more than the decision being wrong,
with that stated where the decision is recorded.

**An invariant no single call site can evaluate is checked against real state.**
Some conditions only a bug can violate hold across processes, across runs or over accumulated state
rather than within one call, such as every accepted item reaching a terminal state, a queue
draining, or two representations that `data-integrity.md` requires to stay in sync actually
agreeing. Each has something that reads the real state and reports a discrepancy, such as a
reconciliation pass, a periodic verifier or a comparison of two counters. A discrepancy is a failure
that needs a person, so it reaches one as the Should on alerts below describes, rather than only
being logged. Where that state is not already durable, the record the check reads is written on
purpose, because a check with nothing to read cannot be written at all. The check reports rather
than halting: the output it disagrees with has already been produced, so there is nothing left to
interrupt. Left to tests, such an invariant is exercised only by data a test author made up, while
the obligation reads as discharged because a test names it.

**A failure's input is recoverable from what was recorded.**
Determinism makes a failure replayable in principle, and the retained input is what makes it
replayable in fact. Where an input arrives as a stream, a large payload or a value the process
consumes and discards, what is recorded at the failure reconstructs it: the value itself, or a
reference that still resolves to it. Where the input is personal data, the reference is the only
available form, because `privacy.md` rules out the value.

**What a diagnosis needs is kept until its failure has had time to come to light.**
A record deleted before anyone asks answers nothing. Logs, traces, retained inputs and whatever a
reference in them points to are kept for longer than the slowest routine way their failures are
found, such as the interval of a check that looks for a broken invariant, or the billing cycle in
which a wrong charge appears. `reliability.md` bounds how large stored data grows; this sets how
long a record lasts at least. Where `privacy.md` sets a shorter limit for personal data, that limit
holds, and the gap it leaves is recorded where retention is configured.

**A failure that needs a person reaches one.**
A deployed system raises an alert when its errors cross a threshold, when it stops serving, and when
scheduled work does not complete in its window. Work that should happen regularly but runs only when
someone remembers to trigger it counts as scheduled work, because it can stop happening just as
silently. An alert on a failure that harms users for as long as it lasts, such as an outage, arrives
within minutes: its window, how often it is evaluated and how long delivery takes add up to minutes,
not hours, so a daily summary does not stand in for it. Each alert goes to a channel that people
actually read, not one they have muted, and that outlives any one person's assignment, such as a
team channel rather than one person's inbox. People move between systems, and an alert sent to
someone who has moved on reaches nobody. A failure that is recorded but never surfaced is
diagnosable only by someone who already suspects it, so a system can satisfy every other claim in
this file and still fail without anyone knowing. `deployment.md` covers regressions a release
introduces; this covers everything that breaks while nobody is deploying.

**An alert that a missing signal would silence also fires when the signal stops.**
An alert on a count, such as errors above a threshold, sees zero when the errors stop and also when
the logs or metrics that carry them stop arriving, so a system whose telemetry has failed looks
healthier than ever. Each such alert treats missing data as firing, or is paired with one that fires
when that same signal has been absent for longer than its usual interval. A probe that sees the
system stop serving does not stand in for either, because a system can keep serving while its
telemetry fails. That probe runs outside the system, because a system that has stopped cannot report
that it has.

**An alert has been seen to fire, end to end.**
An alert that has never fired is treated as broken, because its query, its threshold, its routing
and the channel at the end of it each fail silently. Each alert has been triggered by a real event
in the system it watches since its query, threshold or routing last changed, and seen to arrive
where it is meant to. The event matches the alert's own condition: an alert that can also fire
another way, such as on missing data, has not proven its query and threshold by firing that other
way. Where triggering it in production would page someone, the proof is split in two: the alert's
condition is shown to match a test event, such as one raised in staging, and a test notification is
shown to reach the channel. The split leaves the threshold and its timing unproven, and that gap is
recorded where the alert is documented. The change that adds or edits an alert records what
triggered it and where the notification arrived, so a reviewer checks the record rather than asking
for the proof.

**Each alert says what it means and links to where to look.**
An alert's text names the condition that fired it and what that condition means for the system, and
links to the logs or dashboard that show why. The person who receives it is often not the person who
wrote it, and an alert only its author can interpret goes unanswered until its author sees it.

**A warning about a state stops once the state has passed.**
Some warnings report a state the system checks again later, such as a value that does not match what
the system expects. Others report an event, such as a change that arrived without notice. An event
cannot be checked again, so its warning stays until someone has seen it. A state's warning is
withdrawn by the system when a later check finds the state has passed, not left for a person to
clear, and the withdrawal is recorded, so the record shows how long the state lasted. A warning that
outlives its cause tells its readers something false, and teaches them to ignore the channel that
carries it.

So an alert about a state is raised by a check that can also see the state pass, such as a threshold
evaluated over a window. A trigger that fires each time a matching log line or event arrives sees
only arrivals, and can never see that they stopped, so the alerts it raises stay open until a person
or a timeout closes them. Alerting tools often offer both, and the trigger is the easier one to set
up.

## Consider

**Alerts are few enough that none gets muted.**
Each alert that fires without needing action teaches its readers to ignore the channel, and once the
channel is ignored, the alerts that matter go unread with the rest. A new system starts with the
alerts the Shoulds in this file and `reliability.md` call for and no others, and gains one only when
a failure went unnoticed without it. This claim is about the count while the channel is still read.
Once people have muted it, its alerts no longer reach anyone, which is the Should that a failure
that needs a person reaches one.

## In scope

- Error paths and recovery paths
- Failure modes
- Quantitative claims backing a design, performance, or process decision
  (rates, latencies, costs, capacity estimates)
- Invariants that hold across processes, runs, or accumulated state rather than
  within a single call
- How long logs, traces and retained inputs are kept
- Alert definitions, their thresholds, their routing, and the signals they depend on
- Warnings the system shows people, such as a banner or a status page

## Out of scope

- Log format, log levels, field naming and telemetry placement, which belong to
  `instrumentation.md`
- Test code
- Handling of an error that is an expected outcome rather than a fault, such as an optional file
  that is absent, where the code says it is expected. A dependency that failed is a fault even when
  falling back from it is expected.
