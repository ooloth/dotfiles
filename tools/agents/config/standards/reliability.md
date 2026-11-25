# Reliability

Reliability belongs to safety: a system that stops doing its job when something
outside its control fails harms everyone who relies on it, and one that stops
without anyone noticing harms them longest. What is outside its control
includes time passing, such as a certificate that expires or a disk that fills
while nobody is changing anything. At its maximum:

- **Safety:** every failure the code does not control, such as a dependency
  that is slow or down, a process that dies or a credential that expires, ends
  in an outcome the code chose, within a time it chose, and work that does not
  need what failed carries on. Once the cause has passed, the system recovers
  without a person, and a failure it cannot recover from reaches a person.
- **Performance:** a failure costs a waiting caller no more than the deadline
  it set, and costs the system no more than redoing the work that failed. What
  handles failure, such as timeouts, retries and health checks, costs the
  healthy path nothing a user can notice.
- **Experience:** from the code and the operator document alone, an operator
  can tell what the system does when each dependency fails and what stops
  working on which date, without having watched it fail.

## Must

**Every call that waits on something outside the process has a timeout.**
A call such as a network request, a database query, a subprocess or a wait for a
lock another process holds gives up after an explicit limit, so an unanswered
call does not block forever. The limit is chosen for the call rather than left
at the runtime's default, which is often no limit at all. The limit bounds the
whole call, from sending the request to reading the last of the answer, not only
each wait for the next piece of it, so a dependency that answers a little at a
time cannot hold the call open indefinitely. A connection meant to stay open,
such as a stream, has a limit on how long it may stay silent instead.

**A timeout is measured by the clock, not by counting.**
A deadline compares elapsed time with a limit. A loop that stops after a fixed
number of polls or retries waits that number times the cost of one pass. That
cost grows when the machine is busy or the dependency is slow, which is when the
timeout matters most. A poll interval sets how often a loop checks, not how long
it waits, and a cap on attempts bounds the work, not the time. Where the clock
is coarse, such as a shell's whole-second counter, a reading can be almost a
second off: a counter that reads 5 may have counted anywhere from just over 4 to
just under 6 seconds. So a deadline on such a clock fires only once the reading
is past the limit, not when it reaches it. A monotonic clock is used where one
exists, so a change to the system time does not move the deadline.

**Transient and permanent failures are distinguished.**
A failure that may succeed on a later attempt, such as a network timeout, a
rate limit or a service that is briefly unavailable, is handled differently
from one that will fail the same way again, such as invalid input, a missing
record or a rejected credential. Retrying a permanent failure wastes resources
and delays the error the caller needs.

**A retried or redelivered operation has the same effect however many times it runs.**
A retry after a timeout cannot tell whether the first attempt took effect, and
a queue may deliver the same message twice. So an operation that changes
state, such as a charge, a sent message or an inserted row, is safe to repeat.
Ways to make it so include a key the receiver uses to drop duplicates, a write
that applies only if the state is still what was read, and a check for an
earlier attempt's effect before acting. An attempt that failed before it could
reach the receiver, such as a refused connection, is safe to retry without any
of these.

**A failure path is reachable from the entry point.**
A guard counts as protection only if something that runs can reach it. One that
nothing reaches, such as a guard in a module nothing imports, in a branch no
caller can select or behind a condition that is never true, reads as protection
and provides none. Whether a raise, an exit or an early return fires at all
depends on the call graph, not on the code around it. So a guard protects
something only when a path reaches it from an entry point that actually runs,
such as a binary, a handler or a scheduled command.

**A failure path's observable effect at the process boundary is intended.**
Every failure the code raises or returns ends in an outcome a person outside the
process can see, such as an exit code, a log line, or work that continues or
stops. That outcome is chosen rather than inherited from wherever the error
happens to land. A handler that catches an error, logs it and returns a default
has decided the operation is recoverable, and code that lets an error escape to
the top has decided it is not. A command or job fails fast only when something
actually exits non-zero, and a service only when the caller gets an error. An
error swallowed three frames down leaves the process reporting success, whatever
it logged along the way.

## Should

**A timeout inside a supervised operation is shorter than its supervisor's.**
An operation that runs under a deadline set from outside, such as a database
statement inside a job or a request behind a proxy, gives up before that
deadline, so it fails with its own diagnosis and releases what it holds. An
operation killed from outside instead leaves no record of why, and work it
started can keep holding resources after the process that started it is gone.

**Transient failures are retried with bounded backoff.**
A transient failure is retried after a delay that grows exponentially with each
attempt and varies at random, so clients that failed together do not all retry
at the same moment when the dependency recovers. The number of attempts is
bounded, and the attempts together fit inside the caller's deadline. Where
several layers of a call chain each retry, their attempts multiply: three
layers that each try three times send a failing dependency 27 calls for one
request. So the bound holds for the chain as a whole, not for each layer.

**Failures are isolated.**
A failure in one dependency does not fail work that does not use it, including
the parts of a response that do not depend on it. Partial success is a valid
outcome when operations are independent. This covers what dependencies share,
such as a connection pool or a worker pool, so a slow dependency cannot use up
capacity that work for another one needs. The same holds within a process: a
fault while handling one request does not affect another request in flight, or
take down the process serving both.

**Recovery from data loss is designed, not assumed.**
Each store of state has a recovery point, which is how much recent work is lost
when its storage is gone, and a recovery time, and both are chosen and written
down. Continuous replication keeps the recovery point near zero when a machine
fails, but it copies a mistaken delete or a corrupting write at once, so
recovering from those needs copies taken at intervals and kept for a while.
Recovery also stays independent of the platform hosting the data. Otherwise a
migration away from that platform takes the recovery path with it. A restore
brings data back but does nothing about the time the system was unreachable:
backups cover data loss, not downtime, and availability needs its own
provision.

A backup is known to work only once data has been restored from it and
checked. Until then nothing shows that it holds what it should.

**Resources are released on every path, after use.**
Resources the code acquires, such as connections, file handles and locks, are
released once the work that needed them is done, whether that work succeeded or
failed. A long-running process that leaks them eventually runs out and then
fails every request that needs one, whatever the resource is. Work cancelled
partway is one of those paths, and `async-coordination.md` makes releasing what
it holds a Must.

**A process asked to stop finishes or hands back the work it holds.**
A stop signal, such as the one a deploy or a restart sends, makes a process
stop accepting new work, finish what it has within the platform's grace period
and return the rest to where it came from, such as a queue. A process that
exits at once drops the requests in flight and can leave a write half done,
and deploys and restarts make that routine rather than rare.

**Work taken from a queue is acknowledged only once its effect is stored.**
A message or job is marked complete after the work it asks for is done, not
when it is received, so a crash in between leaves it to be delivered again
rather than lost. Work delivered again can run twice, which the Must on
retried or redelivered operations covers. A message that fails on every
attempt is covered by the Consider on setting it aside.

**A scheduled job runs one copy at a time, or is safe to run alongside itself.**
A run that takes longer than its interval overlaps the next one, and two runs
over the same data can each pick up the same item or overwrite each other's
output. Either the job is written so that copies running together are safe, or
something keeps a second copy from starting while one runs, such as a lock the
job takes or a platform setting that skips a start. Where overlapping runs race
on the same records, the Must in `data-integrity.md` that concurrent writes are
safe decides.

**Everything that expires is listed with its date, and renews itself or alerts a person in time.**
Anything that stops working on a date, such as a certificate, a domain
registration, an API token or a service account key, fails on that date in a
system that works today and changes nothing, with no deploy to blame. Each one
is listed with its expiry in the operator document, and either renews
automatically or raises an alert early enough for a person to act. Automatic
renewal is still monitored, because renewal can fail silently too.

**A crashed or hung process restarts without a person, and a restart loop raises an alert.**
A process that dies stays dead until someone notices, and a system nobody is
assigned to has no one to notice. The platform restarts it when it exits and
when a liveness check fails, so a hang counts as a failure instead of looking
like a quiet process. Restarting hides a fault as well as recovering from it, so
repeated restarts raise an alert.

**Each service has a health check that tests what it depends on.**
The check answers whether the service can do its job, by reaching what it needs,
such as its database, its queue and the services it calls. A check that only
confirms the process is running reports healthy while every request fails. Where
the platform separates liveness from readiness, a dependency outage makes the
service unready, not dead, so traffic stops without the platform restarting it
in a loop.

**Stored data that grows has a bound.**
Stored data, such as logs, tables, object storage, disks and queues, grows for
as long as the system runs, and an unwatched system runs for a long time. Each
store has a retention rule that removes what is no longer needed, or an alert at
a threshold below its capacity. A full disk stops a system nobody changed.
`privacy.md` bounds how long personal data is kept, and this claim bounds how
large every store grows, personal data included.

## Consider

**A needed dependency that is down is replaced by a stale or default value where one would serve.**
When a dependency the work needs is unavailable, the system can answer with a
substitute, such as the last value it cached or a documented default, rather
than an error. Whether a substitute serves depends on the caller: a stale
exchange rate may do for a displayed price and not for a charge. Where a
substitute is used, the degraded behavior is defined, not accidental. Where the
rest of the work does not need the dependency, such as a page whose optional
panel fails, the Should that failures are isolated covers it.

**Calls to a dependency that keeps failing pause for a period.**
When a dependency is consistently failing, requests to it are suspended for a
period rather than repeatedly attempted, and callers get an error at once
instead of waiting out a timeout. This saves each caller the wait and gives the
dependency time to recover. Where the calls waiting on the failing dependency
hold capacity other work needs, such as a shared worker pool, the Should that
failures are isolated covers it, and pausing the calls is one way to meet it.

**Work beyond capacity is refused early rather than queued until every caller is slow.**
A service that accepts everything sent to it during a spike makes every caller
wait, and callers that time out and retry add load on top. Work that waits in an
unbounded queue past its caller's deadline is then done for nobody. Refusing the
excess at once with an error that says to retry later, or holding it in a
bounded queue, keeps the work the service does accept within its deadlines. An
unbounded queue inside one process is ruled out by `correctness.md`; this claim
covers how much a service accepts from outside.

**Each workload declares the CPU and memory it may use.**
Declared limits, such as a container's CPU and memory limits, keep one workload
from starving its neighbours and let the scheduler place it. Without them, a
memory leak takes down whatever shares its machine, and the failure shows up in
a component that did nothing wrong.

**A message that cannot be processed is set aside where it can be replayed.**
Where work arrives through a queue, a message that fails every retry, or that is
rejected as one that can never succeed, moves to a dead-letter queue instead of
being dropped or retried forever. The dead-letter queue raises an alert when it
holds anything, because each message there is work the system accepted and
never did.

## In scope

- Source files that wait on something outside the process, such as a network
  request, a database query, a subprocess or a lock another process holds
- Queue consumers, scheduled jobs and the code that handles a stop signal
- Entry points and the call graph reachable from them, for the two claims about
  failure paths
- Sites that raise, exit, or return early on failure, wherever they sit
- Deployment and infrastructure config, such as restart policies, health and
  liveness checks, stop grace periods, resource limits, queue settings and
  retention rules
- Stores of state, their backups and replicas, and the operator document's
  recovery and expiry sections
- Certificates, domains and credentials, and how each one renews

## Out of scope

- Calls to in-process functions, except where a failure path passes through
  them
- Test code using mocked or stubbed external dependencies
