# Deployment

A change is safe to deploy when it reaches production without coordination,
cannot corrupt production state, and a bad one is noticed and reversed before
it does lasting harm. When every change meets that, a deploy is cheap and its
risk is small, so deploying many times a day is routine.

## Must

**Deployments are safe to roll back.**
A change that cannot be cleanly reverted — because of a migration, a renamed
config key, a dropped field — has a compensating path identified before it
ships. Rollback is not assumed to be impossible without examination.

## Should

**Changes are small and independently deployable, and the main branch is always deployable.**
Each merge can go to production on its own, without waiting for another change
to land first. A large change ships as a sequence of small ones, each safe by
itself. The exception is a coordinated cutover that cannot be split, such as
moving between infrastructure providers, and that exception is named in the change.

**Every change passes the project's automated checks before it reaches the main branch.**
The checks the project's contributing guide lists run on every change in CI,
and a failing check blocks the merge. A check that runs only on a developer's
machine runs when that developer remembers to, so the main branch stays
deployable only as long as everyone remembers.

**Each deployed version works alongside the version before it.**
During a rollout, and after a rollback, old and new code run against the same
data, config and callers. New code reads what old code wrote, and old code
reads what new code wrote. A change to a schema, stored data shape, message
format, API or config key ships as expand, migrate, contract: the new form is
added alongside the old one, existing use moves to it, and the old form is
removed in a later deploy.

**Rollout is coordinated when consumers exist.**
When a change breaks existing consumers — a removed endpoint, a renamed
config key, a dropped CLI flag — the deployment sequence ensures consumers
are updated alongside or before the breaking change. There is no window
where producer and consumer are incompatible in production.

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

**A deploy is checked against production signals and a regression is reversed in one step.**
After a release, error rates, latency and the system's health checks are
compared against the previous version, and those signals can tell which
version produced them. A regression reaches someone, or something, that can
act within minutes, and reversing it is a single action. Where nothing serves
production traffic, such as a published library or CLI, this does not apply.

**A deployed system's spend has a ceiling, and crossing a threshold below that ceiling raises an
alert.**
Hard limits, such as maximum instances, autoscaling caps and quotas, bound how
fast a runaway loop or a traffic spike can spend. A budget alert set below the
ceiling reaches a person before the ceiling is hit. The budget alert alone is
not enough, because it reports spend only once billing has recorded it, and a
runaway process can spend faster than billing reports. Where nothing deployed
can scale or incur usage charges, this does not apply.

**Migrations don't lock tables or corrupt existing data.**
Schema changes on large tables use strategies that avoid long locks. Existing
rows satisfy any new constraints before enforcement begins.

**The deploy artifact and the local development workflow are separate decisions.**
How something is packaged for production does not dictate how it is run while
being written, and rejecting a tool for one does not decide the other. A
container may be required by the target platform while day-to-day work runs the
process directly; a build step may exist in CI and nowhere else. Conflating them
imports production's constraints into the edit-run loop, where they cost time on
every iteration and buy nothing.

## Consider

**Risky rollouts have a flag.**
Changes that affect a large surface area, modify critical paths, or carry
uncertainty benefit from a feature flag that allows staged rollout and
instant kill-switch.

**Releases are verified and reverted automatically.**
Where traffic is high enough for signals to separate a regression from noise,
a canary or progressive rollout halts and rolls back without waiting for a
person. Below that volume, automatic rollback fires on noise or never fires.

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

## Out of scope

- Code that never runs outside a developer's machine
