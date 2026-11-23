# Standards

Shared standards files for code writing, reviewing and scanning skills.

## What these files are

Each file states **standards** — descriptions of what correct code, and a
correctly running system, look like, written in declarative form and graded by
how strongly they hold. Standards are not instructions to the agent; they are
descriptions of what is true about well-written code and well-run systems.

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

Each bold lead sentence is a standalone claim that can be held up against the code, the running
system or the change and marked true or false, whoever is reading it and why. That's what keeps one
file usable for writing, reviewing, and scanning without rephrasing.

- **Subject is the code, the running system or the change, never the agent.** A claim reads "Errors
  are handled at the level with enough context to act," not "Handle errors at the right level." A
  claim about how work was done is stated as what the change records, so a reviewer checks the
  record: "The change records the deliberate break the test failed against," not "Confirm the test
  against a break."
- **Present tense, declarative, third person.** State a fact about the code,
  not an instruction to the reader.
- **No imperative verbs, in the heading or the body.** A sentence whose main verb is a command,
  such as one that starts with "Use" or "Ensure", reads as an instruction, not a property.
- **The higher tier decides.** When two claims both catch the same gap, whether one contains the
  other or they only overlap, the gap is graded at the higher tier, and the other claim adds detail
  rather than a second grade.
- **General terms rather than products.** A claim names a product or tool only when it is about
  that product or tool.

Wrong: "Validate that names reflect intent."
Right: "Names use domain vocabulary and reflect intent."

## Why this file comes first

This file is read before any category file. The tier definitions below
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

Every file whose scope matches the task at hand is loaded, and so is a file that might match: an
extra file costs one read, and a skipped one means missed guidance.

- **`agent-harness.md`** — agent context files (CLAUDE.md, AGENTS.md), harness config, tool
  permissions
- **`api-design.md`** — exported function signatures, REST/RPC routes, SDK surface, interface
  declarations
- **`async-coordination.md`** — async functions, awaited operations, concurrent tasks, lifecycle
  state (loading/error/success/cancelled), event handlers
- **`bash.md`** — .sh and .bash files and other bash scripts, and any code that builds a command
  line for a command-line tool; loaded alongside language-agnostic files
- **`cli-design.md`** — CLI binaries, command definitions, flag declarations, help text, exit code
  handling
- **`code-readability.md`** — all non-generated source files; loaded for every code task
- **`code-structure.md`** — directory layout, import graphs, module boundaries, feature organisation
- **`config.md`** — startup code, env var read sites, feature flag and mode switch read sites,
  config parsing and validation
- **`correctness.md`** — all non-generated source files; loaded for every code task
- **`css.md`** — stylesheets, style blocks, CSS-in-JS, design tokens; contrast, motion, responsive
  layout
- **`data-integrity.md`** — data models, storage shapes, schema changes, migrations, write paths,
  transactions
- **`decision-making.md`** — architecture decision records, spikes and benchmarks, any choice of
  tool, runtime, platform or data shape
- **`dependencies.md`** — package manifests, such as package.json or Cargo.toml,
  base images, automatic update config, platform and runtime versions
- **`deployment.md`** — any change to code that runs in a deployed environment; CI/CD config,
  Dockerfiles, infrastructure manifests, migration files, spend limits; how a change is
  divided into PRs, in any repo; pre-commit hook config and the task runner's check command
- **`developer-experience.md`** — README, CONTRIBUTING.md, onboarding docs, setup instructions,
  the operator document (SYSTEM.md)
- **`documentation.md`** — any file change that affects documented behaviour or has accompanying
  docs; diagrams and tables in ticket comments and PR descriptions
- **`error-handling.md`** — fallible operations, error propagation paths, user-facing error output
- **`git.md`** — any code that runs git commands; loaded alongside language-agnostic files
- **`instrumentation.md`** — logging, metric and trace call sites; log format, levels and field
  content
- **`observability.md`** — what a failure has to reveal, what must be recorded for it to, invariants
  no call site can check, alerts and whether they reach a person
- **`performance.md`** — design choices that put a network hop on a path, loop bodies, database
  queries, hot-path functions, large or unbounded data operations
- **`privacy.md`** — any code that handles, stores, logs, or transmits user data or PII; API
  responses; analytics events
- **`python.md`** — .py files; loaded alongside language-agnostic files
- **`reliability.md`** — network requests, database queries, external service calls, file handles,
  resource cleanup; restarts, health checks, expiry, growth bounds and resource limits in
  deployment config
- **`rust.md`** — .rs files; loaded alongside language-agnostic files
- **`security.md`** — HTTP handlers, auth and permission checks, file I/O, secret handling, input
  parsing, audit logging of production changes
- **`terraform.md`** — .tf and .tfvars files, CI/CD that runs plan or apply
- **`testing.md`** — test files and test directories
- **`type-design.md`** — type definitions, function signatures, domain models, API boundary types
- **`typescript.md`** — .ts and .tsx files; loaded alongside language-agnostic files
- **`user-experience.md`** — any user-facing output: CLI messages, API error responses, error text,
  onboarding docs

The file names above match the file system, and a name that doesn't is a gap to repair.
