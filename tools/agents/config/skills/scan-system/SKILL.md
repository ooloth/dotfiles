---
name: scan-system
description: Check a running system against the standards, component by component, with evidence from the live system, and rank what is incomplete. Works on a new system or one that has been running for years. TRIGGER when setting up or deploying a new system, taking over or getting reassigned to an existing one, or asked whether a system is in good shape. Code-only review belongs to scan-standards.
argument-hint: 'Path to the system''s repo [optional, defaults to the current directory]'
---

Scope: $ARGUMENTS (if empty, the repo the user named, or else the repo in the current directory).

This skill checks what a system is like while it runs: whether its alerts fire, its backups
restore, its certificates renew and its processes come back after a crash. Reading the code can't
answer those. `scan-standards` reviews the code itself, so don't repeat that work here.

Read `~/.agents/standards/README.md` for what the tiers mean. Step 2 says which standards files to
read for each kind of component.

## Rules

- **Evidence or it doesn't hold.** A claim holds only when you can show what proves it: a CI run,
  a log line, an alert in its channel, a restore that finished, a certificate's renewal record.
  Config that looks right is not evidence that it works.
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
  in.
- **Changes are made the way the project already manages infrastructure.** If it uses Terraform,
  change Terraform, and never create resources by hand alongside it. If the infrastructure was set
  up by hand, make the change by hand with approval, record it in `SYSTEM.md`, and raise bringing it
  under code as a separate question. Never introduce infrastructure-as-code as part of this run.
- **Nothing that pages a person fires without the user's approval,** including test alerts in
  production.
- **Ask rather than guess** about anything the system can't tell you.

## 1. Inventory

List the system's components. Start from `SYSTEM.md` if it exists, and check it against the
running system rather than trusting it. Otherwise work it out from the repo and the platform.

Every system has a repository and pipeline, a cloud project or account, alerting, and an operator
document, even when some of them are missing or empty. Add one entry for each service, scheduled
job or worker, datastore, queue, static site, domain and external dependency the system actually
has. For each, note where it runs and in which environments. Name the types
it doesn't have in one line, and don't check their claims.

Also establish:

- which environments exist (production only, or also staging or development)
- how infrastructure is managed (as code in this repo, as code elsewhere, or by hand)
- which channel alerts go to, and whether people still read it
- who is responsible for the system, and whether anyone has time set aside to support it

List what you couldn't determine as numbered questions and ask them. Carry on with every check that
doesn't depend on an answer, and mark the ones that do as Blocked, naming the question.

## 2. Check each component

For each component, read the standards files listed for its kind in `~/.agents/standards/`, and
check every claim in them that bears on the component:

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

Claims about how code is written belong to `scan-standards`, and claims about a different kind
of component don't bear on this one. Name those together in one line per component rather than
giving each a status. Judge each remaining claim against its own text and note its tier as you read
it. Give each one a status:

- **Holds:** with the evidence that it works.
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

## 3. Rank what fails

Order every Fails, Unproven and Blocked result, worst first:

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
date to today only if this run checked the running system, not just the repo. Creating or editing
it is a change, so it needs approval like any other.

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
2. The results per component, one line per claim, with its status and evidence or reason. Claims
   in one component that share a status and a reason can share a line.
3. The ranked list from step 3, which can be read without the rest.
4. The fixes proposed, waiting for approval.
5. The numbered questions still open.
