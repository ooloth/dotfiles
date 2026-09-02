# Standards

Shared standards files for code writing, reviewing and scanning skills.

## What these files are

Each file states **standards** — descriptions of what correct code looks like,
written in declarative form and graded by how strongly they hold. Standards are
not instructions to the agent; they are descriptions of what is true about
well-written code.

Only the **Must** tier holds unconditionally. **Should** allows documented
exceptions and **Consider** is a judgment call with no default, so this content
is not a set of invariants — a project's genuinely exception-free facts belong
in its own `docs/invariants/` (or `docs/guarantees/`).

This framing makes each file usable in multiple directions without changing the
content:

- A **writing** skill reads a standard as: "produce code that satisfies this"
- A **reviewing** skill reads a standard as: "check whether the code satisfies this"
- A **scanning** skill reads a standard as: "find existing violations of this across a codebase"

Some files include `## In scope` and `## Out of scope` sections that narrow the
scanning target — which surfaces to examine and which to skip.

## Phrasing

Each bold lead sentence must be a standalone claim you could hold up against a
piece of code and mark true or false, regardless of who's reading it or why.
That's what keeps one file usable for writing, reviewing, and scanning without
rephrasing.

- **Subject is the code, not the agent.** Write "Errors are handled at the
  level with enough context to act," not "Handle errors at the right level."
- **Present tense, declarative, third person.** State a fact about the code,
  not an instruction to the reader.
- **No imperative verbs.** Avoid "Use," "Ensure," "Avoid," "Don't" as the
  sentence's main verb — those read as commands, not properties.

Wrong: "Validate that names reflect intent."
Right: "Names use domain vocabulary and reflect intent."

## Read this file first

Always read this file before any category file. The tier definitions below
govern how strongly each standard should be upheld or flagged.

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
- **`css.md`** — stylesheets, style blocks, CSS-in-JS, design tokens; contrast, motion, responsive layout
- **`data-integrity.md`** — data models, storage shapes, schema changes, migrations, write paths, transactions
- **`decision-making.md`** — architecture decision records, spikes and benchmarks, any choice of tool, runtime, platform or data shape
- **`dependencies.md`** — package manifests (package.json, Cargo.toml, pyproject.toml, go.mod)
- **`deployment.md`** — CI/CD config, Dockerfiles, infrastructure manifests, migration files
- **`developer-experience.md`** — README, CONTRIBUTING.md, onboarding docs, setup instructions
- **`documentation.md`** — any file change that affects documented behaviour or has accompanying docs
- **`error-handling.md`** — fallible operations, error propagation paths, user-facing error output
- **`observability.md`** — new code paths, error paths, logging sites, resource allocation
- **`performance.md`** — loop bodies, database queries, hot-path functions, large or unbounded data operations
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
