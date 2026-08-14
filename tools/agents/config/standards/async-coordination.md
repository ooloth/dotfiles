# Async Coordination

Async and concurrent code is correct when shared state is always protected,
async operations are always resolved, race conditions are structurally
impossible rather than guarded against, and the system behaves correctly
whether work runs sequentially or in parallel.

## Must

**Shared mutable state is protected.**
Any state read or mutated by more than one concurrent operation is explicitly
coordinated — through locks, atomics, or channels in threaded code; through
sequencing or structural isolation in single-threaded async code. Concurrent
chains do not interleave over shared read-modify-write sequences. Uncoordinated
concurrent access to shared state does not exist.

**Async operations are awaited.**
Spawned tasks and async operations are either awaited or their completion and
errors are handled through an explicit mechanism. Fire-and-forget is a
deliberate choice, not an oversight, and is documented.

**Cancellation is respected.**
When a cancellation signal is received, in-progress work stops at the next
safe point. Resources held by cancelled work are released.

**Race conditions are eliminated structurally, not patched.**
When async coordination involves multiple possible lifecycle states —
loading, cancelling, retrying, settled — model them as an explicit finite
state machine rather than accumulating boolean flags. Illegal state
combinations become unrepresentable by construction; transitions are the
only path between states, so there is no route to an illegal state that
requires a guard. More than one boolean flag coordinating async behavior
is a signal an FSM is needed.

## Should

**Shared state is minimized.**
Independent work communicates through message passing or immutable data
rather than shared mutable state. The less state that is shared, the fewer
races are possible.

**When explicit locks are used, they are held briefly and acquired in order.**
Work done while holding a lock is limited to what requires the lock.
When multiple locks must be held simultaneously, they are always acquired
in the same order across all call sites. Inconsistent ordering causes
deadlocks; long critical sections increase contention.

**Blocking work is not done in async contexts.**
CPU-bound or blocking operations are offloaded from async executors. Async
runtimes are not blocked by synchronous work.

**Concurrency and queues have explicit bounds.**
Every queue has a maximum size. Every thread pool or task executor has a
concurrency limit. Unbounded growth is not the default. Backpressure is
applied before bounds are exceeded.

**Async continuations read current state, not captured state.**
State consumed after an async operation resolves is read at resolution
time, not captured at call time. A value captured before an await may be
stale by the time the continuation runs — especially common in reactive
or event-driven environments where state updates between initiation and
resolution.

**Partial failure in concurrent operations has a recovery path.**
When a set of concurrent operations can fail independently, the handling
of partial success — which results to keep, which to retry, how to report
— is defined.

## In scope

- Source files containing async functions, thread or task spawning, locks, channels, or shared mutable state

## Out of scope

- Fire-and-forget patterns explicitly documented as intentional
- Test code using synchronous equivalents for simplicity
