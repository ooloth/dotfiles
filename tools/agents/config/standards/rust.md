# Rust

Rust code upholds these invariants in addition to all language-agnostic references.

## Must

**Error handling uses `anyhow` only.**
`thiserror` is not used. `?` propagates errors everywhere. `.context("msg")` provides
human-readable chains. Errors are never silently dropped.

**Structs hold owned types; functions that only read take references.**
Struct fields use `String` not `&str`, `Vec<T>` not `&[T]`. Functions that only read
take `&str`/`&[T]`. Return owned values, not references to borrowed data.

**No lifetime annotations.**
If `'a` appears, stop and restructure. Return owned types instead of references with
lifetimes. If lifetimes seem necessary, the design is fighting the borrow checker.

**Secrets are sourced at runtime, never hardcoded.**
Secret values come from outside the binary at runtime (env vars, secret managers, vault
references, etc.) and are never committed to source. The mechanism is project-specific.

**Types holding secrets use `Secret<T>` from the `secrecy` crate.**
`Debug` prints `[REDACTED]`. All access goes through `.expose_secret()`, making every use
site explicit and grep-able. Secret fields on serializable structs use `#[serde(skip)]`.

**All required secrets are resolved at startup.**
Validate and resolve every required secret when the binary starts — not lazily. A missing
or malformed value fails immediately with a clear error message, not silently at first use.

## Should

**The borrow checker is not fought; owned types and clones are preferred.**
If a design requires lifetime annotations or complex borrowing, the design is changed.
Clone values freely across `.await` points and wherever the alternative is lifetime
complexity. Optimize only if profiling shows the clone is a bottleneck.

**Async uses tokio with `features = ["full"]`.**
`#[tokio::main]` at the entry point. `tokio::join!` for parallel independent work.
`tokio::fs` and `tokio::time` instead of std equivalents inside async functions when the
I/O is non-trivial. Reading a small local file (config, HEAD ref, lockfile check) that
completes in microseconds does not need async coloring. Reserve `tokio::fs` for operations
that could realistically block: large reads/writes, directory traversals, or paths that
might be on network mounts.

**CLI uses clap derive macros.**
Annotate structs with derive attributes. Don't use the builder API. Command and flag
definitions live on the struct, not assembled at runtime.

**Prefer `let` over `let mut`; return new values rather than mutating in place.**
Mutation is explicit, not the default. Reach for `let mut` only when mutation is
genuinely needed. Functions that transform inputs into new values are easier to
test and compose.

**Tokio is used for concurrency, not convenience.**
Don't reach for `tokio::spawn`, channels, or `Arc<Mutex<T>>` just because an async
runtime is present. Those introduce synchronization complexity. Use synchronous code
when there is no concurrency benefit.

**A test records what a stub was asked in a plain local that the stub's closure captures by
`&mut`.**
`let mut calls = Vec::new();` beside `|call| calls.push(call)` needs no shared ownership, and
the test reads `calls` once the code under test returns. `Rc<RefCell<T>>` is the recorder only
where a helper reused by several tests returns the stub, because a returned closure that borrows
a local needs a lifetime annotation. `Arc<Mutex<T>>` is never a test recorder, since nothing in
the test runs concurrently, and a `future_not_send` lint on an async test helper is answered by
the plain local, not by making the recorder `Send`.

**An empty result is asserted equal to a typed empty value when its type compares and prints.**
`assert_eq!(hits, Vec::<Hit>::new())`, or `assert_eq!(text, "")`, prints what was found when it
fails, where `assert!(hits.is_empty())` reports only that something was there. Clippy's
`assert_is_empty` catches some of the second form and not all of it, so the rule holds by
convention where the lint is silent. A type without `PartialEq` and `Debug` keeps
`assert!(x.is_empty())` rather than gaining a derive for the test's sake.

**Code that branches on an `Option`, a `Result` or an enum uses `match`.**
A `match` names every case, in order, and the compiler checks that none is missing.
`map_or` and `map_or_else` hide the two branches in closures with the default case passed first,
`.map(f).unwrap_or(d)` hides them the same way, and a chain of `if let … else` hides which cases
it leaves out. Combinators that take a single path, such as `map`, `and_then`, `unwrap_or`,
`is_some_and` and `?`, are not branching when used alone and stay. Clippy's `option_if_let_else`
and `single_match_else` push the other way, so a project that holds this rule allows those two and
lists `map_or` and `map_or_else` under `disallowed-methods` in `clippy.toml`. It keeps
`map_unwrap_or` on, because that lint flags `.map(f).unwrap_or(d)`, and the `map_or` it suggests
is then refused with the reason to write a `match`. `clippy --fix` applies that suggestion, so a
`map_or` it writes is rewritten as a `match` by hand. `.map(f).unwrap_or_default()` has the same
shape and no lint flags it, and with `option_if_let_else` allowed nothing flags an `if let … else`
chain either, so both hold by convention.

## Consider

**`assert!`, `unwrap()`, and `unreachable!()` are correct for invariant violations.**
Panicking on an impossible state is idiomatic Rust. Use `unwrap()` on values that must
exist by construction, `unreachable!()` for arms that cannot be reached,
`assert!` for invariants that must hold.

**`Arc<T>` is the optimization path when a clone is measured to be too expensive.**
Cloning an `Arc<T>` is an atomic refcount increment, not a copy of the data. Reach
for it when profiling shows a clone is a bottleneck — not before.

**`debug_assert!` is reserved for expensive checks on hot paths.**
`assert!` fires in both debug and release builds. `debug_assert!` fires only in
debug. Use `debug_assert!` only when the check is expensive and the invariant is
structurally enforced elsewhere in release builds. `assert!` is the right choice
in almost all cases.

**Unit tests live in inline `#[cfg(test)] mod tests` modules.**
Tests for a module are co-located in the same file, keeping the test and the code
it covers adjacent.

**Parameterized tests use `rstest`.**
When the same test shape applies to multiple inputs or variants, `rstest` replaces
copy-pasted test functions with `#[case]` annotations.

**Snapshot tests use `insta`.**
When the expected value is large or deeply structured, `insta` replaces hand-written
expected values with stored snapshots that can be updated intentionally.

**Property-based tests use `proptest`.**
When a behavior should hold for any valid input across a range, `proptest` replaces
a handful of chosen examples with generated cases.

**Mutation testing uses `cargo-mutants`.**
`cargo-mutants` verifies that tests catch logic errors by mutating operators, return
values, and conditions and reporting which mutations survive. Run periodically, not
on every commit — it is intentionally slow.

**HTTP client integration tests use `wiremock`.**
When testing a function that makes HTTP requests, `wiremock` starts a real local
server and asserts on the actual requests received — method, path, headers, and
body. This catches URL construction bugs, missing headers, and serialization errors
that trait-based mocks cannot.

## In scope

- All .rs files in the repo

## Out of scope

- Auto-generated .rs files (e.g. build.rs output, protobuf-generated)
- Vendored code not maintained in this repo
