# References

Shared reference files for code writing, reviewing and scanning skills.

## What these files are

Each file states **invariants** — facts about what correct code looks like,
written in declarative form. Invariants are not instructions to the agent; they
are descriptions of what is true about well-written code.

This framing makes each file usable in multiple directions without changing the
content:

- A **writing** skill reads an invariant as: "produce code that satisfies this"
- A **reviewing** skill reads an invariant as: "check whether the code satisfies this"
- A **scanning** skill reads an invariant as: "find existing violations of this across a codebase"

Some files include `## In scope` and `## Out of scope` sections that narrow the
scanning target — which surfaces to examine and which to skip.

## Read this file first

Always read this file before any category file. The tier definitions below
govern how strongly each invariant should be upheld or flagged.

## Tiers

**Must** — no exceptions. A violation is always wrong. Writing skills never
produce violations. Reviewing skills flag violations immediately regardless of context.

**Should** — true by default. A violation is wrong unless there is a documented,
deliberate reason for it. Writing skills follow this unless they can name the
exception. Reviewing skills flag violations and ask whether the exception applies.

**Consider** — worth raising for judgment. Neither right nor wrong by default.
Writing skills think about it. Reviewing skills surface it when the trade-off
seems unresolved.

## File index

Load every file whose scope matches the task at hand. When in doubt, load it —
a false positive costs one read; a false negative means missed guidance.

- **`agent-harness.md`** — agent context files (CLAUDE.md, AGENTS.md), harness config, tool permissions
- **`api-design.md`** — exported function signatures, REST/RPC routes, SDK surface, interface declarations
- **`async-coordination.md`** — async functions, awaited operations, concurrent tasks, lifecycle state (loading/error/success/cancelled), event handlers
- **`cli-design.md`** — CLI binaries, command definitions, flag declarations, help text, exit code handling
- **`code-readability.md`** — all non-generated source files; load for every code task
- **`code-structure.md`** — directory layout, import graphs, module boundaries, feature organisation
- **`config.md`** — startup code, env var read sites, config parsing and validation
- **`correctness.md`** — all non-generated source files; load for every code task
- **`data-integrity.md`** — database models, schema changes, migration files, write paths, transactions
- **`dependencies.md`** — package manifests (package.json, Cargo.toml, requirements.txt, go.mod)
- **`deployment.md`** — CI/CD config, Dockerfiles, infrastructure manifests, migration files
- **`developer-experience.md`** — README, CONTRIBUTING.md, onboarding docs, setup instructions
- **`documentation.md`** — any file change that affects documented behaviour or has accompanying docs
- **`error-handling.md`** — fallible operations, error propagation paths, user-facing error output
- **`observability.md`** — new code paths, error paths, logging sites, resource allocation
- **`performance.md`** — loop bodies, database queries, hot-path functions, large or unbounded data operations
- **`plans.md`** — plan documents: problem statement through implementation-ready design, produced before non-trivial or ambiguous implementation begins
- **`privacy.md`** — any code that handles, stores, logs, or transmits user data or PII; API responses; analytics events
- **`python.md`** — .py files; load alongside language-agnostic files
- **`reliability.md`** — network requests, database queries, external service calls, file handles, resource cleanup
- **`rust.md`** — .rs files; load alongside language-agnostic files
- **`security.md`** — HTTP handlers, auth and permission checks, file I/O, secret handling, input parsing
- **`terraform.md`** — .tf and .tfvars files, CI/CD that runs plan or apply
- **`testing.md`** — test files and test directories
- **`type-design.md`** — type definitions, function signatures, domain models, API boundary types
- **`typescript.md`** — .ts and .tsx files; load alongside language-agnostic files
- **`user-experience.md`** — any user-facing output: CLI messages, API error responses, error text, onboarding docs

If you notice the file names above have diverged from the file system, offer to repair the list.
