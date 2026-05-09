# Deployment

A change is safe to deploy when it can be rolled out without corrupting
production state, rolled back if problems emerge, and coordinated safely
when existing consumers depend on the current behaviour.

## Must

**Deployments are safe to roll back.**
A change that cannot be cleanly reverted — because of a migration, a renamed
config key, a dropped field — has a compensating path identified before it
ships. Rollback is not assumed to be impossible without examination.

## Should

**Rollout is coordinated when consumers exist.**
When a change breaks existing consumers — a removed endpoint, a renamed
config key, a dropped CLI flag — the deployment sequence ensures consumers
are updated alongside or before the breaking change. There is no window
where producer and consumer are incompatible in production.

**Migrations don't lock tables or corrupt existing data.**
Schema changes on large tables use strategies that avoid long locks. Existing
rows satisfy any new constraints before enforcement begins.

**Deployment ordering is considered.**
When a change requires coordinating config updates, service restarts, or
infrastructure changes, the required order is identified and documented.

## Consider

**Risky rollouts have a flag.**
Changes that affect a large surface area, modify critical paths, or carry
uncertainty benefit from a feature flag that allows staged rollout and
instant kill-switch.
