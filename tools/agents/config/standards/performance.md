# Performance

Performance is how little anyone waits on the path they wait on, and how little of the machine's
time, memory, network and battery the work spends, as `decision-making.md` defines it. At its
maximum:

- **Safety:** what the work costs stays bounded for every input a caller can send, so no input, load
  or wait stalls the system or exhausts a resource, and a faster path returns what the slower one
  would.
- **Performance:** every path someone waits on costs only the round trips and computation the work
  cannot avoid on the network and hardware it runs on, judged at its slowest cases, and a process
  waiting for something spends nothing while it waits.
- **Experience:** code is as simple as the need allows, and where it is not, the count or
  measurement that justified the complexity is recorded where a maintainer will find it, so they
  can tell whether it still pays for itself.

## Must

**A design records what each path it adds will cost.**
The largest costs, such as the algorithm, the data layout and the number of round trips, are set by
the design, and they get more expensive to change as code is built on them. So a design that adds a
path, a store or a dependency, whether in a design document or in the description of the change that
builds it, estimates what each path costs at the scale it must handle and on the worst input it
accepts, in round trips, data moved, data stored, memory held and computation. A cost that does not
bind gets a reason instead of a number. `decision-making.md` asks every architectural decision to
name the resources that do not bind, and this claim adds the estimate of what each path costs.

**A design adds no network hop it could avoid unless the hop buys a property nothing else
provides.**
A hop costs safety and performance, and through them experience. It adds latency to every operation
that crosses it, a failure mode that can stall rather than fail, and often a capacity ceiling
someone else sets. So an option that adds one names the property it buys. A property here is one the
system's derived list requires, such as a latency it must meet or data it must keep, and a gain such
as a higher hit rate counts only where such a requirement needs it. A saving in money or effort is
not a property. Nor is a benefit the system already owes by other means. The tell is a hop justified
by price, by convenience, or by something another requirement already delivers.

**Algorithmic complexity is justified, and judged at the worst input a caller can send.**
Operations over large or unbounded inputs use algorithms whose complexity is appropriate for the
expected scale and no higher than the task requires. Work that must read every element is linear at
best, and a lookup or a check on a bounded part of the input needs less. Where someone else controls
an input's size or shape, such as a client, a library or another team's data, the cost is judged at
the worst input they can send, not the typical one. A cost that is fine on real traffic but
quadratic on a crafted input is a denial of service. Two things bound it: a method whose proven
worst case is affordable at any size the input can reach, or a cap on the input's size before the
work starts. Costs that hide behind a single line are examined like a nested loop, such as a
backtracking regular expression, a recursive parser, or string building that copies on every step. A
cost paid on a shared path, such as an event loop, a lock or a hook that runs on every request or
log entry, is paid again by everything waiting on that path. Work that grows faster than linearly
with an input that can grow states the bound that keeps it affordable beside it: the cap on the
input, or the reason the input stays small.

**A change that adds complexity for speed records the count or measurement that justified it.**
Code is as simple as the task allows unless something shows that the simple version is too slow. For
a cost that follows from structure, such as the number of round trips or how an algorithm grows on
the worst input, a count is enough, and the design's estimate can be that count. For anything else,
such as a constant factor, a hand-written data structure, a cache or an object pool, a profile or a
benchmark shows where the time goes. The change records what was measured, on what input and
hardware, how many runs, and the figures before and after, in a place a reviewer reads, such as a
comment, the change's description or its commit message. Complexity added on a guess costs every
later reader and may buy nothing. Code read on its own, without the change that added it, is not
graded against this claim, because its record may sit in history the reader was not given.

**A cache's key holds every input its cached result depends on.**
A cache hands back an earlier answer in place of computing a fresh one. When its key leaves out an
input the answer depends on, such as the user, the locale or a flag, one caller gets the answer
computed for another. That answer is wrong for them, and when it holds someone's data, it is a leak.
An input here is a value the caller or its context supplies, such as an argument or the current
tenant. Data the result is read from, which can change at its source, is what makes an entry stale,
under the claim on staleness. An input that the cache's rule for staleness already covers, such as
the date, under a rule that drops every entry when the date changes, is covered by that rule and
need not be in the key.

## Should

**Work a path repeats with the same result is done once and reused.**
A value that does not change between passes of a loop is computed before the loop. A query whose
answer cannot change within a request is issued once in that request. A value that is the same on
every run, such as a tool's install path that a shell's start-up script looks up each time a shell
opens, is worked out ahead of time and read from where it was saved. Where keeping a result means
adding a cache, the claims on caches apply, and so does the Must on complexity added for speed.

**A cache names what makes an entry stale.**
An entry is refreshed or dropped by a rule the code states, such as a time limit, a version in the
key, an event from the source, or a lifetime no longer than the data stays valid, such as one
request or one run. A cache whose entries cannot change, such as one keyed by a content hash, says
so. A cache with no rule serves an old answer for as long as it lives, and nothing reports that it
did.

**A hot path allocates once what it would otherwise allocate on every call.**
A hot path is one that a profile or a count shows taking a large share of the time, such as a
parser's inner loop. On it, a buffer or object whose size is known ahead of time is allocated once
and reused, because each allocation costs time and, in a runtime with a garbage collector, a pause
later. Elsewhere, allocation follows whatever reads most clearly, under the Must on complexity added
for speed.

**A loop makes no query, API call or file read per item where one batched call could serve them
all.**
Each call pays a round trip, so a loop over n items that calls once per item, the N+1 pattern, waits
n times where it could wait once. Where the store or service offers a batched form, such as a query
on a list of keys or a bulk endpoint, the loop gathers its keys and makes one call. Where it offers
none, the calls run at the same time, under the claim on independent waits. A statement run per row
against an embedded database inside one transaction pays no round trip and is outside this claim.

**Data is filtered, counted and joined where it is stored, and a read fetches only what its caller
uses.**
Moving rows to the application to discard most of them costs the transfer, the memory and the
decoding of each one, and the cost grows with the table rather than with the answer. So the work
happens in the store, such as counting with a count query rather than fetching every row, or
filtering in the query rather than in a loop over its result, and a read names the columns or fields
its caller uses. Where the store cannot do the work, such as a filter on a value only the
application computes, the read is paginated or streamed.

**Large datasets are paginated or streamed.**
An operation that reads a result set or a file that can grow without bound reads it in pages or as a
stream, so the memory it holds is bounded by the page rather than by the data. Fetching everything
into memory is not the default for a collection that can grow.

**Code that waits on another process's state blocks or sleeps between checks, rather than
spinning.**
A loop that checks a file, a socket or a status again as soon as the last check returns keeps a core
busy for the whole wait, even when each check is an awaited call. It slows the process it is waiting
on when the two share a machine, and it drains a battery. Where the other side can signal, such as
through a file-system event, a blocking read or a condition variable, the waiter blocks until it
does. Where it cannot, the loop sleeps between checks for an interval set by how soon the change
must be seen. A brief spin before blocking, such as inside a lock's implementation, is the
exception. `reliability.md` covers how long the wait may last in total.

**Independent waits on a path someone waits on run at the same time, not one after another.**
Two network calls, queries or file reads that do not need each other's results cost the slower of
the two when they run together, and the sum of both when they run in turn. So on a path a caller
waits on, independent waits start together, within the bounds `async-coordination.md` sets on
concurrency. Work whose order matters, or that shares state, keeps its order.

**A memory figure names the counter it was read from, and a figure for what a process holds comes
from the operating system's count of the process's physical memory.**
A figure with no counter named cannot be checked, and the common counters disagree. Naming a call
that returns several counters, such as a runtime's memory-usage function, does not name the counter.
A library's own size report can count a shared object once per reference, such as a dataframe's deep
memory count, which counts a string once for every row that points at it even when the rows share
one object. Resident set size misleads too: on some systems, such as macOS, it leaves out memory the
system has compressed. So a figure a decision rests on is the growth of the process's physical
footprint, measured before and after the step from the operating system's own count, such as
`footprint` or `vmmap --summary` on macOS or, for a container that runs one process, its working
set, and the record names which counter it read. Freed memory an allocator keeps is part of that
footprint, so a drop measured on a laptop is confirmed on the deployed system before it is relied
on.

## Consider

**A user-facing operation has a latency budget, set at a percentile.**
An operation a user waits for, such as a page load, an API response or a search, has a target
latency, expressed at a percentile rather than as an average. A user experiences the slow request,
not the mean of all requests, and an average conceals the tail that gets noticed. Regressions
against that target are caught before shipping.

**CPU-bound work on a path someone waits on, when it splits into independent parts, runs on several
cores where the machine has cores to spare.**
Parts that do not need each other's results, such as pages rendered from one document or files
parsed from one archive, take the time of the slowest part when they run together, and the sum of
all of them when they run in turn. Running them together costs coordination and makes a failure
harder to follow, so the time saved on the slowest case is weighed against that cost, and work done
one part after another on such a path is the case this claim raises.

**Work whose result the waiting caller does not need runs off their path.**
Work done after the answer is known, such as sending a notification or recording an analytics event,
adds its time to the caller's wait though they never see its result. Moving it to a queue or a
background task cuts the wait but adds a way for the work to be lost, so the time saved is weighed
against what losing it would cost.

## In scope

- Design documents and change descriptions that add a path, a store or a dependency, or that report
  a measurement
- Design choices that place work, data or a dependency across a network
- Paths a user or caller waits on, and their latency targets
- Loop bodies
- Database query sites
- Reads of large or unbounded data
- Hot-path functions and the memory they allocate
- Caches and the keys they store results under
- Code that waits on another process's state, such as a polling loop

## Out of scope

- Test code not on production execution paths
- One-off scripts without performance requirements
