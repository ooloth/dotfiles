# Dependencies & Deployment

A change is safe to deploy when its dependencies are justified and trustworthy,
its public contracts are respected, and it can be rolled out and rolled back
without corrupting production state.

## Must

**Breaking changes to public interfaces are explicit.**
When a public API, exported type, CLI command, or config key changes in a
way that breaks existing consumers, that is identified, versioned
appropriately, and communicated. Silent breakage doesn't ship.

**Deployments are safe to roll back.**
A change that cannot be cleanly reverted — because of a migration, a renamed
config key, a dropped field — has a compensating path identified before it
ships. Rollback is not assumed to be impossible without examination.

## Should

**New dependencies are justified.**
Before adding a dependency, existing dependencies and standard library
capabilities are considered. A new dependency is added only when it covers
ground that would be unreasonable to reimplement.

**Migrations don't lock tables or corrupt existing data.**
Schema changes on large tables use strategies that avoid long locks. Existing
rows satisfy any new constraints before enforcement begins.

**Deployment ordering is considered.**
When a change requires coordinating config updates, service restarts, or
infrastructure changes, the required order is identified and documented.

## Consider

**New dependencies are well-maintained.**
Added dependencies have recent activity, a responsive maintainer, and no
known critical vulnerabilities. Bundle size impact is considered for
frontend dependencies.

**Risky rollouts have a flag.**
Changes that affect a large surface area, modify critical paths, or carry
uncertainty benefit from a feature flag that allows staged rollout and
instant kill-switch.
