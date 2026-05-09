# Operational Health

Code is operationally healthy when it performs predictably under real load,
and when failures are visible enough to diagnose without access to the
running process.

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

**Loops don't hide repeated I/O.**
Database queries, API calls, and file reads inside loops are replaced with
batched equivalents. N+1 patterns are resolved before merging.

**Blocking work is not done in async contexts.**
CPU-bound or blocking operations are offloaded from async executors. Async
runtimes are not blocked by synchronous work.

**Large datasets are paginated.**
Operations that could return unbounded result sets use pagination or streaming.
Fetching everything into memory is not the default.

**Log messages are actionable.**
Logs include enough context to act on — relevant IDs, states, and values.
Log levels are appropriate: errors for failures, warnings for degraded states,
info for significant events, debug for diagnostic detail.

## Consider

**Hot paths are free of unnecessary work.**
Operations that run per-request, per-item, or per-frame are scrutinized for
avoidable cost — repeated allocations, redundant lookups, expensive operations
that could be cached or hoisted.

**Resource handles are closed.**
Connections, file handles, and other resources are released after use.
Long-lived processes don't accumulate open handles.

**Resource usage is bounded.**
Memory, connections, threads, and other resources have explicit limits. The
system cannot silently accumulate unbounded resource usage under load.
