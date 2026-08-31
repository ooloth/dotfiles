# Reliability

A system is reliable when it handles external failures gracefully, recovers
from transient problems automatically, and never silently hangs when a
dependency is unavailable.

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

## Consider

**Non-critical dependencies have a degraded fallback.**
When a non-critical dependency is unavailable, the system returns a cached
result, a default, or a reduced feature set rather than a hard failure. The
degraded behavior is defined, not accidental.

**Consistently failing dependencies are circuit-broken.**
When a dependency is consistently failing, requests to it are suspended for a
period rather than repeatedly attempted. This protects the calling system from
cascading failure and gives the dependency time to recover.

## In scope

- Source files containing network requests, database queries, or calls to external services

## Out of scope

- Calls to in-process functions
- Test code using mocked or stubbed external dependencies
