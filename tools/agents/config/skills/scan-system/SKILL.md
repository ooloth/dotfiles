---
name: scan-system
description: Check a running system against the standards, component by component, with evidence from the live system, and rank what is incomplete. Works on a new system or one that has been running for years. TRIGGER when setting up or deploying a new system, taking over or getting reassigned to an existing one, or asked whether a system is in good shape. Code-only review belongs to scan-standards.
argument-hint: 'Path to the system''s repo [optional, defaults to the current directory]'
---

Scope: $ARGUMENTS (if empty, the repo the user named, or else the repo in the current directory).

This skill checks what a system does while it runs: whether its alerts fire, its backups restore,
its certificates renew, its calls time out and its processes come back after a crash. It judges
that behaviour whether config or code decides it. `scan-standards` judges how the code is written,
such as its structure, naming and types, so leave those claims to it.

Read `~/.agents/standards/README.md` for what the tiers mean. Step 2 says which standards files to
read for each kind of component.

## Rules

- **Evidence or it doesn't hold.** A claim holds only when you can show what proves it: a CI run,
  a log line, an alert in its channel, a restore that finished, a certificate's renewal record.
  Config that looks right is not evidence that it works. Where only code can answer a claim, such
  as whether a call is idempotent or sets a timeout, the code is the evidence: cite the file and
  line, and label it code evidence.
- **Judge each claim by the failure it guards against.** Where a claim has no meaning for a
  component, such as runtime error alerts for a static site, it doesn't apply, but the failure
  behind it may take another form. A static site can still stop serving, and content can fail to
  publish. Report the original as Doesn't apply and the other form as a check of its own.
- **Never skip a claim silently.** A claim that doesn't apply says why in one sentence.
- **Must and Should claims are the baseline.** A Should that doesn't hold is reported as Fails,
  with any exception that justifies it. A Consider claim is raised for the user's judgment,
  never reported as a failure.
- **Reading is free; changing needs approval.** Read-only queries to the platform, its CLI or
  `gh` need no approval. Follow any skill that governs the tool, such as `use-gh` before `gh`.
  Anything that changes state needs the user's approval first. If a platform's CLI isn't installed
  or logged in, mark what depends on it as Blocked and suggest the command the user can run to log
  in, which may include installing it. That command is for the user; don't run it yourself. Don't
  run the repo's own code, because it can have side effects. A read that sends data to a
  third party, such as `npm audit` sending the lockfile to the registry, is allowed, but name it in
  the report.
- **Changes are made the way the project already manages infrastructure.** If it uses Terraform,
  change Terraform, and never create resources by hand alongside it. If the infrastructure was set
  up by hand, make the change by hand with approval, record it in `SYSTEM.md`, and raise bringing it
  under code as a separate question. Never introduce infrastructure-as-code as part of this run.
- **Nothing that pages a person fires without the user's approval,** including test alerts in
  production.
- **Ask rather than guess** about anything the system can't tell you.
- **A claim that something is absent rests on two sources that agree.** "No open alerts" and "no
  vulnerable dependencies" can be true. They can also be what a feed shows before it has been
  populated, after a filter it silently ignored, or when a request failed and printed nothing. So
  an absence holds only when an independent second source agrees, such as a local scanner checked
  against GitHub's alert feed, or when the report says why only one source exists. Where two
  sources disagree, report both, and the disagreement is the finding. Pick neither.

## 1. Inventory

List the system's components. Start from `SYSTEM.md` if it exists, and check it against the
running system rather than trusting it. Otherwise work it out from the repo and the platform.

Every system has a repository and pipeline, a cloud project or account, alerting, and an operator
document, even when some of them are missing or empty. Together these four make up one component,
the system as a whole. Add one entry for each service, scheduled job or worker, datastore, queue,
static site, domain and external dependency the system actually has. For each, note where it runs
and in which environments. A component of two kinds, such as an external service that also holds
the only copy of the content, is checked against both kinds' files. Name the kinds the system
doesn't have in one line, and don't check their claims.

Also establish:

- which environments exist (production only, or also staging or development)
- how infrastructure is managed (as code in this repo, as code elsewhere, or by hand)
- which channel alerts go to, and whether people still read it
- who is responsible for the system, and whether anyone has time set aside to support it

List what you couldn't determine as numbered questions, and ask them together with the tool results
below, so the user is interrupted once.

### Confirm the tools are ready

Before checking anything, list the tools the inventory implies: `gh` for the repo, the cloud CLI
for each project or account (`gcloud`, `aws`, `wrangler`), `kubectl` for each cluster, and whatever
gives access to where alerts and logs live, such as Grafana. For each one, confirm with a read-only
command that it is installed, logged in, and pointed at this system, for example `gh auth status`,
`gcloud config get project`, `kubectl config current-context` or `wrangler whoami`.

A tool that isn't installed counts as missing. Don't install it or fetch it with `npx` or similar
to check it, because that downloads and runs code. For a service with no CLI, such as a
notification app, ask the user how they reach it, and treat it as Blocked until they do.

Pointed at this system matters as much as logged in. A tool aimed at the wrong project or cluster
produces confident evidence about a different system, and nothing in the report would look wrong.

Run these commands, like the inventory's reads, as parallel tool calls in one batch rather than one
at a time. Report the results as one list, followed by the inventory's questions. For each tool
that is missing, logged out or aimed elsewhere, give the command the user can run to fix it, such
as `! gcloud auth login`. Then wait. Start the checks once the tools are ready, or once the user
says to carry on without some of them or without answers. In that case, mark every claim that needs
a missing tool or an unanswered question as Blocked from the start, naming it.

## 2. Check each component

Check the components in parallel. Launch one general-purpose subagent per component from the
inventory, including the system as a whole, all in a single message, using the Opus model. The
components don't depend on each other, so the wait is the slowest component rather than the sum of
all of them, and each component's evidence stays out of your context. Opus is slower per component,
but a wrong Holds or a check left unrun hides a gap, and in a side-by-side trial Opus caught
failures and applied the evidence rule where Sonnet did not.

External dependencies the system calls the same way, such as several APIs fetched through one
shared helper at build time, can share one subagent, so a small system doesn't get one agent per
API. Every other component gets its own.

Give each subagent the following. For the parts of this skill, give the path to this file and name
the sections rather than pasting them.

- the component, where it runs, and the environments it runs in
- the standards files listed below for its kind, or for both kinds if it has two
- the tool readiness results from step 1, and which tools it may use
- this skill's "Rules" section, which binds the subagent as much as you
- the instructions below, from "Read the standards files" down to the "Validate" heading, but not
  that section, which is yours
- these limits: read the files itself, spawn no subagents, change nothing, and ask nothing. Where
  it would need to ask or to act, it reports the claim as Blocked or Unproven and names the
  question or the proposed action
- the return format: one entry per claim, with the claim's lead sentence, its file and tier, a
  status field that holds exactly one of the six statuses below and nothing else, and its evidence
  or reason

The rest of this step, up to "Validate", is what each subagent does.

Read the standards files listed for your component's kind in `~/.agents/standards/`, and check
every claim in them that bears on the component:

- **The system as a whole:** `deployment.md`, `dependencies.md`, `security.md`, `observability.md`,
  `developer-experience.md`, and `terraform.md` where Terraform is used
- **Service:** `reliability.md`, `security.md`, `config.md`, `instrumentation.md`,
  `observability.md`
- **Scheduled job or worker:** `reliability.md`, `observability.md`, `instrumentation.md`
- **Datastore:** `reliability.md`, `privacy.md`, `data-integrity.md`
- **Queue:** `reliability.md`, `async-coordination.md`
- **Static site or frontend:** `observability.md`, `performance.md`
- **Domain and edge:** `reliability.md`
- **External dependency:** `reliability.md`

For the system as a whole, run `scripts/security_feeds.py OWNER/REPO --path <checkout>`, found
beside this file, with `uv run`. It reads the repo's Dependabot, code scanning and secret scanning
alerts, runs a local scanner for each lockfile it knows, and prints one definite result per line.
Use its output as the evidence for the `dependencies.md` claim that dependencies are scanned for
known vulnerabilities, and for the `security.md` claims it bears on. A `DISAGREE` line is a finding
to report, never a Holds. A `failed` line makes each claim it bears on Blocked. The script's npm
check sends `package-lock.json` to the npm registry, which the report names, as the rules require.

Claims about how code is written, such as its structure, naming or types, belong to
`scan-standards`. Claims about what the system does at runtime, such as timeouts and retries, are
checked here even when code is what decides them. Claims about a different kind of component don't
bear on this one. Name the skipped claims together in one line rather than giving each a status.
Judge each remaining claim against its own text and note its tier as you read it. Give each one
exactly one of these six statuses, and put any nuance in the evidence, not in the status:

- **Holds:** with the evidence that it works, as a link or as the command you ran and the part of
  its output that proves it, so it can be checked again. Code evidence is labelled as such, with
  file and line.
- **Unproven:** the config or code is there, but nothing shows it working yet. Say what would
  prove it.
- **Fails:** with what you found.
- **Doesn't apply:** with the reason.
- **Blocked:** with what is missing, such as console access or an answer, and who could provide it.
  Use Blocked when you couldn't look, and Unproven when you looked and found the setup but no proof
  that it works.
- **For judgment:** a Consider claim, with what you observed.

Where a claim refers to "the checks the contributing guide lists" and there is no contributing
guide, use the checks the repo defines (package scripts, a justfile or Makefile, pre-commit hooks),
and propose a contributing guide that lists them.

To prove an alert fires without paging anyone in production, split the proof in two. First, show
the alert's condition fires on a test input without notifying anyone: the alerting tool's query
preview against a test event, or the script run against a failing input with notification turned
off. If the script can't turn notification off, propose a way to. Second, send the channel a test
notification and show it arrived. Record what the split leaves unproven, such as the threshold.
Running the alert script runs the repo's code, and sending the test notification is an action, so
a subagent proposes both rather than doing them. You run them once the user approves.

Where a finding comes from code other components share, such as a common retry helper, say so, so
it can be reported once.

Batch independent reads as parallel tool calls in one turn rather than one at a time.

### Validate what the subagents report

A subagent's results are evidence to check, not findings to relay. The costly mistake is a wrong
Holds, because it hides a gap that nothing else will flag. So before ranking, re-run the evidence
for every Holds on a Must or Should claim, in one parallel batch, and confirm the output says what
the subagent said it did. Open each link. A Holds whose evidence doesn't reproduce becomes Unproven,
and say in the report which results you re-checked. Fails, Blocked and Unproven results are already
flagged for the user, so they don't need re-running. But read their evidence: a result whose
evidence says the check wasn't run, such as "not checked" or "didn't review", is not a result.
Run the check yourself, or report it as not examined, so the report doesn't claim more ground than
was covered.

Also:

- **Fix statuses outside the six.** A status such as "Holds, partly" or "Holds by code, Unproven
  live" is not one of the six. Settle it on one, checking the evidence yourself where needed.
- **Reread code evidence.** For a Holds that rests on code evidence, open the file and line and
  confirm the code says what the subagent said.
- **Resolve contradictions.** Compare results that concern the same thing across components, such
  as a redirect one subagent tested and another relied on. Where they disagree, check it yourself
  and correct the wrong one.
- **Report shared findings once.** A finding several subagents reported from shared code goes
  under the component where the code lives, naming the others it affects. Code no single component
  owns, such as a shared retry helper, goes under the system as a whole.

Then gather the questions and proposed actions the subagents reported, remove duplicates, and ask
the questions as one numbered list.

## 3. Rank what fails

Order every Fails, Unproven and Blocked result, worst first, putting each in the first category
it fits. Rank an Unproven or Blocked result by what it would mean if it turned out to fail, and
mark it as unconfirmed:

1. **Failures that happen with nobody changing anything.** Expiring certificates, domains and
   credentials, data growing without a bound, crashes nothing restarts, platforms past end of
   support, dependencies nobody updates, and alerts that reach nobody. Many systems run for long
   stretches with nobody assigned to them, and these failures arrive anyway.
2. **Failures that cause the most harm when they happen,** such as lost data, an outage, a leaked
   secret or runaway spend.
3. **Everything else,** cheapest to fix first.

Where one fix needs another first, say so. Alerts need a working channel, and automatic updates
need CI that blocks failing changes.

## 4. Propose fixes

Propose fixes for the top few results, not all of them, each with what would change and how it will
be proven. Apply a fix only after the user approves it, then re-check the claim and report the new
evidence.

## 5. Update SYSTEM.md

Create or update `SYSTEM.md` at the repo root from the inventory and results. Link to consoles and
saved queries rather than copying what they show. Link to it from the repo's agent context file
(`AGENTS.md` or `CLAUDE.md`) so agents read it at the start of a session. Set the "last checked"
date to today only if this run could see the platform's own state, through its console, CLI or
API. Public probes such as `curl` and `whois` are not enough on their own. Creating or editing
it is a change, so show the draft in the report and write it only once the user approves.

```markdown
# <Project> system

Status: <proof of concept | in use | wound down> · Last checked against reality: <date>
Responsible: <person or team, and whether anyone has time set aside to support it>

## What it does

One paragraph: what the system is for, and who uses it.

## Components

For each: what it does, where it runs, and a link to it in the platform's console.

## Data

Each datastore: what it holds, where it lives, how it is backed up, and whether it can be rebuilt.

## External dependencies

APIs and services it calls, and what happens to it when each one is down.

## What expires

Each certificate, domain, credential and platform version, with its date and how it renews or is
upgraded.

## Where to look

- Logs: a saved query or console link per component
- Dashboards: links
- Alerts: each one, what it means, where it posts, and anything about it that is unproven

## How to operate it

Deploy, roll back, restart, and run a job by hand. Each as the exact command or a link.

## Known failure modes

Symptoms seen before, what caused them, and what fixed them.

## Open gaps

What the last scan found that still fails or is unproven.
```

## Report

End with:

1. The inventory, one line per component.
2. The results per component, grouped by status, one line per claim with its evidence or reason.
   Claims that share a status and a reason can share a line. Name any read that sent data to a
   third party.
3. The ranked list from step 3, which can be read without the rest.
4. The fixes proposed, waiting for approval.
5. The `SYSTEM.md` draft, waiting for approval.
6. The numbered questions still open.
