# Dependencies

A codebase has healthy dependencies when every library earns its place,
is trustworthy, and does not accumulate unexamined risk over time.

## Must

**New dependencies are justified.**
Before adding a dependency, existing dependencies and standard library
capabilities are considered. A new dependency is added only when it covers
ground that would be unreasonable to reimplement. The cost — a new
transitive dependency tree, a new maintenance obligation — is weighed
against the benefit.

## Should

**Dependencies are well-maintained.**
Added dependencies have recent activity, a responsive maintainer, and no
known critical vulnerabilities. A dependency with no recent activity carries
uncertainty about future compatibility and security response.

**Dependency integrity is verified.**
Lockfiles or checksums confirm that installed versions match what was
reviewed. Dependencies come from trusted, official sources.

## Consider

**Frontend dependencies are scrutinized for bundle size.**
Added libraries are weighed against their impact on bundle size. Libraries
that cover only the needed functionality are preferred over large
general-purpose alternatives when the use case is narrow.

## When scanning

**Surfaces:** Cargo.toml, package.json, requirements.txt, go.mod, Gemfile, and their lockfiles.

**False positives to skip:** dev-only and test-only dependencies, which carry lower risk than production dependencies.
