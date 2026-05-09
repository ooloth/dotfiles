# Performance

Code performs well when it is fast enough for its context, and when the work
done to make it faster is driven by measurement rather than assumption.

## Must

**Algorithmic complexity is justified.**
Operations over large or unbounded inputs use algorithms whose complexity is
appropriate for the expected scale. O(n²) over large inputs is examined before
merging, not after a production incident.

**Optimization is not premature.**
Code is not made complex in the name of performance without profiling evidence
that the simpler version is too slow. Clarity is the default; optimization is
justified by measurement.

## Should

**Repeated expensive work is cached.**
Computations or lookups that are expensive and produce stable results are
memoized or cached at an appropriate scope. The cache invalidation strategy
is explicit.

**Work is not repeated unnecessarily.**
Values that are computed once are stored and reused. Queries that return the
same result within a request are not issued multiple times.

**Memory allocation in hot paths is minimized.**
In performance-sensitive paths, allocations are scrutinized. Reuse, pooling,
or pre-allocation is preferred over allocating on every call.

## Consider

**Performance budgets exist for user-facing operations.**
Operations that a user waits for — page loads, API responses, search results —
have a target latency. Regressions against that target are caught before
shipping.

**Parallelism is used for independent work.**
Independent I/O operations or CPU-bound tasks that can safely run in parallel
are structured to do so rather than executed sequentially.
