# Dependencies

A codebase has healthy dependencies when every library earns its place,
is trustworthy, and does not accumulate unexamined risk over time.

## Must

**Each dependency is justified.**
A dependency earns its place by covering ground that would be unreasonable
to reimplement, and one that has stopped covering it is removed. Before
adding one, existing dependencies and standard library capabilities are
considered. The cost — a transitive dependency tree, a maintenance
obligation — is weighed against the benefit. The cost that persists is rarely the integration,
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

**Dependency and base image updates arrive automatically as proposed changes, and CI checks each
one.**
A tool such as Dependabot or Renovate opens a change for each update to the
manifest's dependencies, the container base image and the CI actions. CI runs
on each one, so a passing update can be merged by whoever looks next, and a
failing one says what broke. Without this, a system nobody is assigned to falls
further behind every month, and the eventual upgrade is one large change made
under pressure, usually because a vulnerability forced it.

**The platforms the system runs on are within their support period, and their end dates are
known.**
The language runtime, the OS or base image, the cluster version and each
managed service have an end-of-support date set by someone else. After it,
security fixes stop, and the provider may upgrade or remove the platform on its
own schedule. Each date is recorded in the operator document, and an upgrade is
planned before the date arrives rather than forced after it.

## Consider

**Frontend dependencies are scrutinized for bundle size.**
Added libraries are weighed against their impact on bundle size. Libraries
that cover only the needed functionality are preferred over large
general-purpose alternatives when the use case is narrow.

## In scope

- Cargo.toml, package.json, requirements.txt, go.mod, Gemfile, and their lockfiles
- Third-party code loaded at runtime: script tags, dynamic imports from external origins
- Container base images, runtime version declarations, and update tool config such as
  `dependabot.yml` or `renovate.json`
- The versions of the platforms and managed services the system runs on

## Out of scope

- Dev-only and test-only dependencies, which carry lower risk than production dependencies
