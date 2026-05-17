---
name: Rust invariants
description: Language-specific invariants for Rust code; load in addition to language-agnostic references when Rust files are in scope
type: reference
---

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

**Secrets come from environment variables.**
Never read from files or hardcode. Accessed via `std::env::var`. Injected at runtime
by `op run --env-file=.env` or equivalent.

## Should

**The borrow checker is not fought; owned types and clones are preferred.**
If a design requires lifetime annotations or complex borrowing, the design is changed.
Clone values freely across `.await` points and wherever the alternative is lifetime
complexity. Optimize only if profiling shows the clone is a bottleneck.

**Async uses tokio with `features = ["full"]`.**
`#[tokio::main]` at the entry point. `tokio::join!` for parallel independent work.
`tokio::fs` and `tokio::time` instead of std equivalents inside async functions.

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

## Consider

**`assert!`, `unwrap()`, and `unreachable!()` are correct for invariant violations.**
Panicking on an impossible state is idiomatic Rust. Use `unwrap()` on values that must
exist by construction, `unreachable!()` for arms that cannot be reached,
`assert!` for invariants that must hold.

**`match` is preferred over chains of `if let`.**
Pattern matching is exhaustive and forces handling of all cases. Chains of `if let`
hide the unhandled cases and are harder to extend.

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

## In scope

- All .rs files in the repo

## Out of scope

- Auto-generated .rs files (e.g. build.rs output, protobuf-generated)
- Vendored code not maintained in this repo
