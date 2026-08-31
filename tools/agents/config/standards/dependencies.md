# Dependencies

A codebase has healthy dependencies when every library earns its place,
is trustworthy, and does not accumulate unexamined risk over time.

## Must

**New dependencies are justified.**
Before adding a dependency, existing dependencies and standard library
capabilities are considered. A new dependency is added only when it covers
ground that would be unreasonable to reimplement. The cost — a new
transitive dependency tree, a new maintenance obligation — is weighed
against the benefit. The cost that persists is rarely the integration,
which is paid once. It is the second model of the world now being carried:
another vocabulary, another set of failure modes to recognise, and another
place to look when something breaks.

## Should

**Dependencies are well-maintained.**
Added dependencies have recent activity, a responsive maintainer, and no
known critical vulnerabilities. A dependency with no recent activity carries
uncertainty about future compatibility and security response.

**Dependency integrity is verified.**
Lockfiles or checksums confirm that installed versions match what was
reviewed. Dependencies come from trusted, official sources.

**Third-party code loaded at runtime is pinned and verified too.**
A script fetched from a CDN when a page loads has no manifest, no lockfile
and no install step, so nothing confirms that what runs today is what was
reviewed — and it executes with full access to the page. An exact version
is pinned and its integrity verified, by subresource integrity, a vendored
copy, or both. A floating tag is less audited than anything in a manifest,
not more, despite feeling lighter.

**Dependencies are scanned for known vulnerabilities.**
Security audits run regularly — `npm audit`, `cargo audit`, `pip-audit`, or
equivalent. Known vulnerabilities in transitive dependencies are not silently
accumulated; they are triaged and resolved or explicitly accepted.

## Consider

**Frontend dependencies are scrutinized for bundle size.**
Added libraries are weighed against their impact on bundle size. Libraries
that cover only the needed functionality are preferred over large
general-purpose alternatives when the use case is narrow.

## In scope

- Cargo.toml, package.json, requirements.txt, go.mod, Gemfile, and their lockfiles
- Third-party code loaded at runtime: script tags, dynamic imports from external origins

## Out of scope

- Dev-only and test-only dependencies, which carry lower risk than production dependencies
