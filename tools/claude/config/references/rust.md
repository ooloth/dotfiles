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

**Clone freely; don't fight the borrow checker.**
Clone values across `.await` points and wherever the alternative is lifetime
complexity. Optimize only if profiling shows the clone is a bottleneck.

**Async uses tokio with `features = ["full"]`.**
`#[tokio::main]` at the entry point. `tokio::join!` for parallel independent work.
`tokio::fs` and `tokio::time` instead of std equivalents inside async functions.

**CLI uses clap derive macros.**
Annotate structs with derive attributes. Don't use the builder API. Command and flag
definitions live on the struct, not assembled at runtime.

## Consider

**`assert!`, `unwrap()`, and `unreachable!()` are correct for invariant violations.**
Panicking on an impossible state is idiomatic Rust. Use `unwrap()` on values that must
exist by construction, `unreachable!()` for arms that cannot be reached,
`assert!` for invariants that must hold.

**`match` is preferred over chains of `if let`.**
Pattern matching is exhaustive and forces handling of all cases. Chains of `if let`
hide the unhandled cases and are harder to extend.

## Out of scope

- Auto-generated .rs files (e.g. build.rs output, protobuf-generated)
- Vendored code not maintained in this repo
