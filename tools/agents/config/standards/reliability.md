# Reliability

A system is reliable when it handles external failures gracefully, recovers
from transient problems automatically, and never silently hangs when a
dependency is unavailable. It stays reliable while nobody is changing it: the
failures that come from time passing, such as expiry, growth and crashes nobody
sees, are handled without a person.

## Must

**All external calls have timeouts.**
Network requests, database queries, and calls to external services always have
an explicit timeout. An unanswered request does not block indefinitely. The
timeout value is deliberate, not the runtime's default.

**Transient and permanent failures are distinguished.**
A failure safe to retry (network timeout, rate limit, temporary unavailability)
is handled differently from one that is not (invalid input, not found,
authentication failure). Retrying a permanent failure wastes resources and
delays the error signal to the caller.

**A failure path is reachable from the entry point.**
A guard in a module nothing imports, a branch no caller can select, a check
behind a condition that is never true — each reads as protection and provides
none. Whether a raise, an exit, or an early return fires at all is a property
of the call graph, not of the code around it, so it is established by tracing
from the binary, handler, or scheduled command that actually runs.

**A failure path's observable effect at the process boundary is intended.**
Every raise has an outcome a person outside the process can see: an exit code,
a log line, work that continues or stops. That outcome is chosen, not inherited
from wherever the error happens to land. An error caught by a handler that logs
and returns a default has decided the operation is recoverable; an error that
escapes to the top has decided it is not. Code fails fast only when something
actually exits non-zero — an error swallowed three frames down leaves the
process reporting success, whatever the message said on the way past.

## Should

**Transient failures are retried with bounded backoff.**
When a transient failure is detected, the operation is retried with exponential
backoff and jitter. Retry attempts are explicitly bounded. Jitter prevents
thundering herd when a downstream service recovers.

**Retried operations are idempotent.**
Any operation that may be retried due to a timeout or transient failure produces
the same outcome on repeat. Duplicate execution is safe by design.

**Failures are isolated.**
A failure in one dependency does not cascade to unrelated operations. Work
that can proceed without the failing dependency does proceed. Partial success
is a valid outcome when operations are independent. The same holds within a
process: a fault while handling one request does not affect another request in
flight, or take down the process serving both.

**Recovery from data loss is designed, not assumed.**
Anything that stores state has a recovery point — how much recent work is lost
when its storage is gone — and a recovery time. Continuous replication and a
periodic copy differ by exactly that first number, so choosing between them is
choosing how much work a failure is allowed to destroy. Recovery also stays
decoupled from the platform hosting it, or a migration quietly takes the
recovery path with it. And restoring returns the data while saying nothing
about how long the system was unreachable: backups cover data loss, not
downtime, and availability needs its own provision.

A backup that has never been restored is a hypothesis, not a backup.

**Resource handles are closed after use.**
Connections, file handles, and other resources are released when the work
that required them is done. Long-lived processes that accumulate open handles
degrade over time — resource exhaustion is a reliability failure, not just
a memory concern.

**Everything that expires is listed, and raises an alert before it expires.**
TLS certificates, domain registrations, API tokens, service account keys and
other credentials each stop working on a date. A system that works today and
changes nothing still fails on that date, with no deploy to blame. Each one is
listed with its expiry in the operator document, and either renews
automatically or raises an alert early enough for a person to act. Automatic
renewal is still monitored, because renewal can fail silently too.

**A crashed or hung process restarts without a person, and a restart loop raises an alert.**
A process that dies stays dead until someone notices, and on a system nobody is
assigned to, nobody notices. The platform restarts it when it exits and when a
liveness check fails, so a hang counts as a failure instead of looking like a
quiet process. Restarting hides a fault as well as recovering from it, so
repeated restarts reach a person, as `observability.md` requires.

**Each service has a health check that tests what it depends on.**
The check answers whether the service can do its job: reach its database, its
queue and the services it calls. A check that only confirms the process is
running reports healthy while every request fails. Where the platform
separates liveness from readiness, a dependency outage makes the service
unready, not dead, so traffic stops without the platform restarting it in a
loop.

**Stored data that grows has a bound.**
Logs, tables, buckets, disks and queues grow for as long as the system runs,
and an unwatched system runs for a long time. Each one has a retention rule
that removes what is no longer needed, or an alert at a threshold below its
capacity. A full disk stops a system nobody changed. `privacy.md` bounds how
long personal data is kept; this bounds everything else.

## Consider

**Non-critical dependencies have a degraded fallback.**
When a non-critical dependency is unavailable, the system returns a cached
result, a default, or a reduced feature set rather than a hard failure. The
degraded behavior is defined, not accidental.

**Consistently failing dependencies are circuit-broken.**
When a dependency is consistently failing, requests to it are suspended for a
period rather than repeatedly attempted. This protects the calling system from
cascading failure and gives the dependency time to recover.

**Each workload declares the CPU and memory it may use.**
Container requests and limits, or the platform's equivalent, keep one workload
from starving its neighbours and let the scheduler place it. Without them, a
memory leak takes down whatever shares its machine, and the failure shows up in
a component that did nothing wrong.

**A message that keeps failing is set aside where it can be replayed.**
Where work arrives through a queue, a message that fails every retry moves to a
dead-letter queue instead of being dropped or retried forever. The dead-letter
queue raises an alert when it holds anything, because each message there is
work the system accepted and never did.

## In scope

- Source files containing network requests, database queries, or calls to external services
- Entry points and the call graph reachable from them, for the two standards about failure paths
- Sites that raise, exit, or return early on failure, wherever they sit
- Deployment and infrastructure config: restart policies, health and liveness checks, resource
  limits, queue settings, retention rules
- Certificates, domains and credentials, and how each one renews

## Out of scope

- Calls to in-process functions, except where a failure path passes through them
- Test code using mocked or stubbed external dependencies
