# Project Harness

A project's harness is sound when an agent encountering it for the first time
can understand its purpose, verify its own work by observing the running
system, and know what constraints govern its decisions — without asking the
author.

## Must

**A project context file exists and states what the project builds and why.**
`CLAUDE.md`, `AGENTS.md`, or an equivalent file is present at the repo root.
An agent reading only that file understands the system's purpose, domain, and
the problem it solves. The file is not a changelog or a setup guide — it is
an orientation document.

**How to run the project's checks is documented or discoverable.**
The commands to run tests, linting, type checking, and builds are stated
explicitly or reachable from a standard entry point. An agent can verify its
changes without asking what to run.

**Non-obvious constraints are stated explicitly.**
Gotchas, forbidden patterns, intentional deviations from convention, and
decisions that would surprise a competent agent are written down. An agent
should not have to discover these by making mistakes.

**A documented way to invoke the running system locally exists.**
The agent can exercise real code paths — not only run tests. A CLI command,
script, or documented invocation sequence lets the agent observe what the
system actually does, not only what tests assert it should do.

## Should

**An instruction that governs an act is loaded at that act, not at session start.**
Memory of a rule decays over a session, and work built on the paraphrase looks
compliant while breaking the rule. Four mechanisms, in order of reliability:
check what can be checked, put the load step inside the procedure where it is
needed, phrase triggers as recurring rather than preconditional, and keep the
rules short enough that re-reading is cheap.

**A fact a shared skill needs about one project lives in that project's docs, not in a copy of the
skill kept in that project.**
Copies of one skill kept in several projects drift apart: an improvement made in one copy never
reaches the others, and each copy's project facts reach only the sessions that run it. The shared
skill reads the project's context file and the docs it points to, and the project states there
what the skill needs, such as where work is tracked, how it is ordered and what makes a delay
costly, where every agent and maintainer reads it. A shared skill that does not yet read those docs
gains the step that reads them, rather than gaining a copy. A skill scoped to one project holds a
procedure no other project runs, not project facts wrapped around a shared procedure.

**A change to an agent instruction file is verified by replaying the failing
input through a fresh agent.**
Re-reading the edited file confirms only that it says what its author meant.
What matters is what an agent carrying no memory of the discussion does with
it, and that is observable: an ephemeral agent given only the instruction
files and the exact input that failed produces a result the author can hold
against the original failure. The replay uses the input that failed rather
than a friendly one, withholds the expected answer from the agent, and runs
again after every subsequent edit, since a result already reported describes
a file state that no longer exists. One input passing can be luck or wording
that fits only that input, so two or three variations of it run too. The same
inputs also run against the file as it was before the change, and the change
counts as verified only where the new file does better than the old one; an
agent that already behaves well without the change shows the change is not
what produced the result. This is the closest an instruction file gets to a
test, and instruction files are otherwise unverified.

**A claim about how an instruction will behave is replayed before it is argued
from.**
Predicting that an instruction would be ignored, read too broadly, or filled in
as busywork is a claim about an observable thing, and the observation costs one
ephemeral agent and the input in question. Argued rather than run, the
prediction decides what gets written while never being checked, and it is
indistinguishable from taste to everyone including its author. The procedure is
the replay above, run before the decision instead of after it: give an agent
carrying no memory of the discussion the instruction as it would be written and
the input that would test it, withhold the expected answer, and read what it
does.

**A file a later session resumes from holds what that session would otherwise get wrong or redo,
and nothing else.**
A session that resumes from a file trusts what it finds there and skips what it does not, so each
part of the file is tested by what goes wrong on resume without it. The user's goal in their own
words stays, because the work was chosen against it. Each item's state stays, with when it was last
read, so staleness shows. The reason behind an order stays, so the order is not reshuffled for
nothing. What was left out stays, with why, so it is not read again and added back. Questions still
open stay, so an answer can be matched to them. A history of changes, a record of past agreements
and anything a ticket already holds fail the test, and each makes the file slower to read and
quicker to go stale. A file saved after every reply makes ending a session cost nothing.

**Evidence an agent reports is written by the tool that observed it, and the report quotes it
from there.**
An agent that retypes a command's output can trim it, misremember it, or leave out the run that
cut against its conclusion, and a reader can't tell, because a retyped quote looks the same as a
faithful one. So each command and its raw output are saved as they run, with the artifact they
observed named beside them. The report quotes the saved files and lists every observation it
doesn't cite. The exception is an observation no tool can capture, such as a person reading a
device's screen, which the report labels as reported by that person.

**Usage patterns are described.**
How users or callers interact with the system is documented. An agent
understands the intended interaction model — what inputs the system accepts,
what outputs it produces, and what a typical session looks like.

**Key domain concepts are defined.**
Terms, entities, and relationships that a general-purpose agent might
misunderstand or map incorrectly to general programming concepts are
explained. An agent that misunderstands the domain will make plausible but
wrong decisions.

**Non-obvious architectural decisions are recorded with rationale.**
When the structure of the codebase reflects a deliberate tradeoff — a chosen
pattern, a rejected alternative, a constraint imposed by context — the reason
is written down. An agent that understands the why is less likely to
accidentally undo it.

**Agent tool permissions are explicitly configured.**
The harness states what operations are permitted and disallowed — file paths
the agent should not touch, commands it should not run, external systems it
should not call. Explicit configuration is more reliable than convention.

**The harness surfaces check failures automatically during agent sessions.**
When an agent's changes break a test, fail a lint rule, or violate a build
constraint, the failure is visible to the agent in the same session without
requiring human intervention. The mechanism — hooks, a mandatory check step,
a CI result the agent is instructed to read — is not prescribed; what matters
is that the agent can observe and self-correct.

**Observability signals are documented and discoverable.**
Logs, traces, and metrics the system emits are described: where they appear,
what format they use, and what the key fields mean. An agent should not need
to grep source code to discover that signals exist or to understand what they
say.

**The signals are rich enough to diagnose failures from the outside in.**
When a code path misbehaves at runtime, an agent reading logs or traces can
identify the cause without reading implementation code. This is the critical
distinction from tests: tests validate what the author thought to check;
runtime signals reveal what actually happened. Sparse or unstructured signals
force the agent back to static analysis, losing the validation power of a
running system.

**The agent is told how to trigger specific code paths.**
Beyond "run the test suite", the harness documents how to exercise particular
behaviours — "to test the auth flow, invoke X; to verify cache behaviour,
do Y." This lets the agent validate a hypothesis empirically rather than
only statically.

**An agent reaches any signed-in screen in development without a person's credentials.**
Where the running system sits behind a login, development has a shortcut that signs an agent in
as a named test user in one step, such as a development-only route, and the project's context
file says how to use it. The shortcut exists only in development builds, and a check that runs
fails if it is reachable in any deployed environment.

## Consider

**The project's maturity is indicated.**
An agent should know whether it is working on a prototype, an internal tool,
or a production system. That context changes how aggressively Should
violations should be treated and how much churn is acceptable.

**Health check and status reads are commands the agent can run.**
A quick invocation the agent can run to assess overall system state, before and after a change,
is described. So is each read a person otherwise makes by hand to answer an operational question,
such as which version is deployed, which flags are on for a user, or which users hit an error. A
health check provides a fast outside-in signal that the system is behaving normally.

**Representative output is documented.**
Example log lines, trace snippets, or metric values under normal conditions
are recorded. An agent that has never run the system can recognise a normal
signal versus an anomalous one without needing to run it first.

**External integrations and non-obvious runtime dependencies are catalogued.**
Services, APIs, or environment conditions the system depends on at runtime
are listed. An agent that doesn't know a dependency exists cannot account for
its absence or failure.

**Cross-harness compatibility is maintained.**
If agent tools other than the primary harness are used alongside it, their
config files are symlinked to the canonical equivalents rather than
maintained separately — for example, `AGENTS.md` → `CLAUDE.md` and
`.agents/skills` → `.claude/skills`. A single source of truth prevents the
two from drifting.

## In scope

- `CLAUDE.md`, `AGENTS.md`, and any equivalent project context files
- `.claude/`, `.agents/`, and equivalent harness config directories
- `README.md` at the repo root
- Files under `docs/` or equivalent documentation directories

## Out of scope

- Production monitoring dashboards not accessible during local development
- Observability infrastructure the project does not own or configure
- Third-party tool configuration files unrelated to agent interaction
