# Deployment

Deployment is how a merged change reaches the people it serves, and how a bad one is taken back. A
deploy is the moment a change meets production's data, traffic and spend, so it bears on all three
properties `decision-making.md` defines. At its maximum:

- **Safety:** a change reaches production without breaking anything already running, cannot
  corrupt stored data or spend without a limit, and can be undone. A bad one is noticed from
  production's own signals and reversed before it does lasting harm.
- **Performance:** a change reaches production in the time its build and checks need and no more,
  a deploy makes no user wait or lose a request, and reversing one is a single action.
- **Experience:** deploying is a decision, not a procedure. Nobody coordinates, remembers a step or
  holds the order of operations in their head, and a reviewer sees each change at a size they can
  judge whole.

## Must

**Every deployment can be undone, by a rollback or by a compensating path identified before it
ships.**
A change that a plain rollback cannot undo, such as one with a migration that drops data, a renamed
config key or a dropped field, names the steps that reverse its effect before it ships. Whether a
rollback works is established by examining what the change alters, and is not assumed either way.

## Should

**Changes are small and independently deployable, and the main branch is always deployable.**
Each merge can go to production on its own, without waiting for another change
to land first. The exception is a coordinated cutover that cannot be split, such as
moving between infrastructure providers, and that exception is named in the change.

**A large change ships as thin vertical slices, each verified end to end before the next builds
on it.**
Each slice runs end to end through every layer it needs, so it can be checked by running the system
and not only by its tests. The first slice carries the assumption most likely to be wrong, usually
how an external system actually behaves, so the slices after it build on something observed rather
than assumed. A piece that nothing calls yet cannot be exercised, so parts that cannot be verified
without each other stay in one slice. A change that alters no behaviour, such as a refactor or the
expand step of expand, migrate, contract, is a slice of its own.

**A change couples independent designs only when separating them would gain nothing.**
A change can introduce decisions that do not depend on each other, such as a new data model, a
change to behaviour existing callers rely on and a new integration. Such a change is split along
those decisions when reviewing or observing them apart is worth the extra change. It is worth it
when one decision rests on an assumption only the running system can confirm, or when each needs a
reviewer's full attention. Lines changed measure this poorly: tests and fixtures are cheap to read,
and one decision spread over many files is still one decision. A split that gains neither costs a
review and a deploy and returns nothing.

**Every change passes the project's automated checks before it reaches the main branch.**
The checks the project's contributing guide lists run on every change in CI,
and a failing check blocks the merge. A check that runs only on a developer's
machine runs when that developer remembers to, so the main branch stays
deployable only as long as everyone remembers.

CI runs those checks by calling the same task-runner command a developer runs, such as
`just check`, rather than naming each tool in the pipeline config. Two lists of checks drift
apart: a check added to one is missing from the other, so a change can pass CI and fail on a
laptop, or the reverse. With one list, a check added to it runs in CI with no pipeline change.
Where CI needs a setting a laptop doesn't, such as a cap on test workers, it passes that setting
to the same command instead of keeping its own copy of the list.

**A pre-commit hook that checks or fixes the repo's files runs a check the task runner's check
command also runs.**
It uses the same installed tool version and the same include and exclude rules as that command. The
hook runs in two places. At commit time it checks the staged files among those the command covers.
Where the check command runs the hooks itself, it checks every file. A hook that checks something
the command doesn't runs only for developers who installed hooks, so CI never sees it. A hook that
formats with its own pinned version writes changes the command then rejects. A hook that covers a
different set of files lets through files the command fails on. A hook that checks the commit itself
rather than its files, such as a commit-message linter or a guard against committing to the main
branch, has no counterpart in the check command and falls outside this rule.

**The artifact that reaches production is the one that passed the checks.**
The build runs once for each change, and every environment deploys that output, named by a
reference that cannot move, such as an image digest or a version number that is never reused. A
rebuild for each environment, or a deploy by a tag that can be pointed elsewhere, such as `latest`,
ships something no check has seen, because dependencies resolve again and base images update
between builds. What differs between environments is configuration supplied when the artifact
starts.

**Each deployed version works alongside the version before it.**
During a rollout, and after a rollback, old and new code run against the same
data, config and callers. New code reads what old code wrote, and old code
reads what new code wrote. A change to a schema, stored data shape, message
format, API or config key ships as expand, migrate, contract: the new form is
added alongside the old one, existing use moves to it, and the old form is
removed in a later deploy.

**Compatibility code serves a version or caller that exists.**
A shim, fallback or alias for an old shape of data or an old interface is written only for a
version that shipped or a caller that uses it, and is removed with the last of them.
Compatibility code for something never released keeps a second path alive that nothing
exercises.

**A new restriction that no query can check in advance ships in report-only mode before it is
enforced.**
When the requests or records a new check would reject can't be listed by a query, such as old
clients, links already shared, or data whose problem shows only when it is read, the check first
ships in report-only mode. It logs each case it would reject and lets it through. Enforcement waits
until the logs have covered enough traffic to show each kind of case, and each kind is either fixed
or rejected on purpose. Enforcement can then proceed one kind at a time. Where a query can list
every violator, as with a constraint on stored rows, "Migrations handle existing data" in
`data-integrity.md` applies instead. The report-only logging is removed once enforcement ships.

**A change that breaks existing consumers ships only after every consumer has moved off what it
breaks.**
A removed endpoint, a renamed config key or a dropped CLI flag fails whoever still uses it. The
consumers the team can change move first, and the breaking change ships once none of them relies on
the old form, so producer and consumer are never incompatible in production. Where a consumer
deploys separately from the producer, the Should on parts that deploy separately sets the order. A
consumer outside the team's reach falls under `api-design.md`'s Must on breaking changes.

**Parts that deploy separately work in either order, or ship in a set order.**
When one change touches two parts that deploy on their own, such as a frontend and an API with
separate builds, one part runs ahead of the other for the gap between their deploys, and a browser
tab keeps its old frontend until it reloads. Each half works with the other part both before and
after the change. Otherwise the change is split into PRs that ship in sequence. The PR that adds
what the other part needs, such as a route, a field or an accepted value, is serving in every
environment before the PR that uses it, and a removal ships last, once nothing uses what it removes.

**Unfinished work ships turned off.**
Code for a feature that is not ready merges behind a flag that defaults to off,
so deploying code and releasing behaviour are separate steps. A flag that has
been fully on for all users is removed, along with the code path it disabled.

**Deploying needs no manual steps beyond the decision to deploy.**
Building, migrating, releasing, and the order those happen in, are done by the
pipeline. Each manual step is one a person can skip, do out of order or do
differently from the last person. A step that cannot be automated, such as a
change at a third-party provider, has its required order written down beside
the pipeline.

**Deploys to one environment run one at a time, in the order their changes merged.**
Two deploys that run at once can finish in either order, so an older version can replace a newer
one with nothing to show it happened, and their migrations can run against each other. A deploy
that starts while another to the same environment is running waits for it, and a waiting deploy of
an older change is dropped once a newer one is queued behind it. A rollback is the deliberate
exception, and it runs as its own action.

**A deploy drops no work in flight.**
A new instance receives traffic only once its readiness check passes, and the platform's wait
before it forces an old instance to exit is longer than that instance needs to finish or hand back
what it holds, as `reliability.md`'s Should on stopping describes. A platform that kills the old
instance at once fails every request in progress at every deploy, so frequent deploys show up as a
steady error rate.

**A manual step's gate names a state the system is known to enter, and the command that reads it.**
A runbook step that waits on a condition, such as a controller having seen a commit or a resource
having gone, holds only if that condition is reachable. Controllers often skip work rather than
record it. For example, a GitOps parent with pruning off runs no sync for a commit that only removes
its children, so the runbook's condition "shows the merge commit as synced" never becomes true, and
an operator waiting for it can only wait indefinitely or guess. Each gate names the field or output
that changes, the command that reads it, and the value expected, and that value is one the author
has seen the system produce.

**A deploy is checked against production signals and a regression is reversed in one step.**
After a release, signals such as error rates, latency and the system's health checks are compared
against the previous version, and those signals can tell which version produced them. A regression
reaches someone, or something, that can act within minutes, and reversing it is a single action.
Where nothing serves production traffic, such as a published library or CLI, this does not apply.

**A change made to move a measurable outcome has its signal, baseline and expected range in place
before its behaviour serves.**
The outcome can be a latency, an error rate, a memory figure, a response size, or anything else the
change sets out to move. The signal that measures it is recording before the change's behaviour
serves: it ships in an earlier deploy, or with the change while the change stays behind a flag that
is off until the baseline is taken. A baseline is taken with the exact query the after-measurement
will use, repeated over separate windows of the same length until the spread between runs shows
the noise. The expected effect is written as a range whose width comes from that noise. Where
nothing serves production traffic, such as a published library or CLI, the signal is a benchmark,
run on the base commit and on the change on the same machine.

**A measured outcome's result is recorded against its range, and a result outside it is explained.**
After the change serves, the same query runs again over windows that start after it began serving
and match the baseline's length. The baseline, the result, the delta, the range and the verdict are
recorded together, with the gap between the estimate and the result, so the team can see whether its
estimates run high or low. A move no larger than the noise is no change, in either direction. A
result outside the range, better or worse, is explained before it is relied on, because either way
the model behind the estimate was wrong. A result short of the range, a result within the noise, and
a result that could not be measured all mean the change has not been shown to reach its target. Each
of those is settled one of three ways and recorded with its reason: accepted as close enough, kept
open with follow-up work for the gap, or closed as not achievable.

**A value the system cannot read back is confirmed by its effect.**
Once a write-only value is set, such as a secret held by another service, a credential in a store
the deployer cannot read, or a header or token pushed through someone else's API, nothing shows what
was stored. A plan, a diff or a successful write proves only that something was sent. A change that
sets such a value is confirmed after it takes effect by exercising what the value enables, such as
one authenticated request through the path it secures, and reading the result. A change to how the
value is set, such as a new attribute, a library or provider upgrade, or a rotation, is confirmed
the same way. The write can succeed with a wrong value, and the old value it replaced may already
have stopped working.

**A deployed system's spend has a ceiling, and crossing a threshold below that ceiling raises an
alert.**
Hard limits, such as maximum instances, autoscaling caps and quotas, bound how
fast a runaway loop or a traffic spike can spend. A budget alert set below the
ceiling reaches a person before the ceiling is hit. The budget alert alone is
not enough, because it reports spend only once billing has recorded it, and a
runaway process can spend faster than billing reports. Where nothing deployed
can scale or incur usage charges, this does not apply.

**A migration holds no lock that blocks the application for longer than a request can wait.**
Some schema changes rewrite or scan a whole table while holding a lock, such as adding a column
whose default is computed for every row or building an index without the database's concurrent
option, and every request the lock blocks waits until it finishes. Where that would take longer than
a request's timeout, the change runs in a form that takes only brief locks. What a migration does to
rows that already exist falls under "Migrations handle existing data" in `data-integrity.md`.

**The deploy artifact and the local development workflow are separate decisions.**
How something is packaged for production does not dictate how it is run while
being written, and rejecting a tool for one does not decide the other. A
container may be required by the target platform while day-to-day work runs the
process directly; a build step may exist in CI and nowhere else. Conflating them makes every edit
pay production's packaging cost, such as an image rebuild. The packaged form is checked by the
production-like run that `developer-experience.md` describes, not by the edit-run loop.

**A test stage in a multi-stage Dockerfile is one the final stage depends on.**
BuildKit builds only the stages the target stage depends on ("BuildKit only
builds the stages that the target stage depends on", Docker's
[multi-stage builds](https://docs.docker.com/build/building/multi-stage/) page,
under "Differences between legacy builder and BuildKit"). So a stage that runs
tests against the built artifact, and that nothing copies from, is skipped
without a message, and the image builds whether the tests pass or fail. The
test stage writes a file once its tests pass, and the final stage copies that file, so the tests
run on every build and a failure stops the image. A cached test layer replays an earlier run's
success, so a build that has to run the tests afresh passes `--no-cache-filter <stage>`.

## Consider

**Risky rollouts have a flag.**
Changes that affect a large surface area, modify critical paths, or carry
uncertainty benefit from a feature flag that allows staged rollout and
instant kill-switch.

**Releases are verified and reverted automatically.**
Where traffic is high enough for signals to separate a regression from noise,
a canary or progressive rollout halts and rolls back without waiting for a
person. Below that volume, automatic rollback fires on noise or never fires.

**The time from merge to serving in production is known, and spent on work rather than waiting.**
A fix that rolls forward reaches users no sooner than the pipeline delivers it. Steps that wait
rather than work, such as a queue for a shared runner, a fixed delay, or stages that could run side
by side but run in turn, lengthen every deploy, the urgent one included. A pipeline whose time is
recorded shows when it has grown.

**Deployed resources carry labels that make cost and ownership attributable.**
Each resource names the system it belongs to and its environment, so a bill can
be split by system and an unknown resource can be traced to an owner.
`terraform.md` states this for resources Terraform manages. It holds equally
for resources created any other way.

## In scope

- Application code that runs in a deployed environment
- CI/CD pipeline configs
- Migration files
- Deployment scripts, Dockerfiles, and infrastructure-as-code manifests
- How a change is divided into PRs, in any repo that ships through them
- Pre-commit hook config and the task runner's check command

## Out of scope

- Code that never runs outside a developer's machine, apart from how its changes are divided
  into PRs, the pre-commit hooks that check it, and the check command and CI that run its checks
