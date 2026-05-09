# Concurrency

Concurrent code is correct when shared state is always protected, async
operations are always resolved, and the system behaves correctly whether work
runs sequentially or in parallel.

## Must

**Shared mutable state is protected.**
Any state accessed by more than one thread or task is protected by a lock,
atomic operation, or channel. Unprotected concurrent writes don't exist.

**Async operations are awaited.**
Spawned tasks and async operations are either awaited or their completion and
errors are handled through an explicit mechanism. Fire-and-forget is a
deliberate choice, not an oversight, and is documented.

**Cancellation is respected.**
When a cancellation signal is received, in-progress work stops at the next
safe point. Resources held by cancelled work are released.

## Should

**Shared state is minimized.**
Independent work communicates through message passing or immutable data rather
than shared mutable state. The less state that is shared, the fewer races are
possible.

**Locks are held for the minimum duration.**
Work done while holding a lock is limited to what requires the lock. Expensive
operations — I/O, computation — are moved outside the critical section.

**Locks are acquired in a consistent order.**
When multiple locks must be held simultaneously, they are always acquired in
the same order across all call sites. Inconsistent ordering is the cause of
deadlocks.

## Should

**Concurrency and queues have explicit bounds.**
Every queue has a maximum size. Every thread pool or task executor has a
concurrency limit. Unbounded growth is not the default. Backpressure is applied
before bounds are exceeded.

**Partial failure in concurrent operations has a recovery path.**
When a set of concurrent operations can fail independently, the handling of
partial success — which results to keep, which to retry, how to report — is
defined.
