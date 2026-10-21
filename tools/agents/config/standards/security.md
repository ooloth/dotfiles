# Security

Code is secure when it treats all external input as untrusted, keeps secrets
secret, and enforces identity and permission at every protected boundary.

## Must

**Inputs are validated at system boundaries.**
All data entering the system — API requests, CLI arguments, file uploads,
environment variables, external API responses — is validated before use.
Validation happens at the boundary, not deep in business logic.

**Injection is not possible.**
SQL queries use parameterized statements. Shell commands don't interpolate
user input. HTML output is escaped. User data never reaches an interpreter
as executable code or a navigable path. Escaping is a property of the
rendering approach rather than a step someone remembers: where the tool
escapes by default, the failure mode is a deliberate opt-out, which is
visible in review, rather than an omission, which isn't.

**Secrets are not hardcoded or logged.**
Credentials, API keys, tokens, and passwords exist only in environment
variables or secret stores. They don't appear in source code, logs, error
messages, or stack traces. This includes local development: a file of real
values on a developer's disk is protected only by an ignore rule, and an
ignore rule is one mistake away from failing. Where a committed file
describes what the environment needs, it holds *references* to a secret
store rather than the values themselves, so committing it is harmless by
construction rather than by vigilance.

**Authentication and authorization are enforced.**
Every protected route or operation verifies identity and permission before
proceeding. Auth checks are not bypassable by omitting a parameter or header.

**Errors don't leak sensitive information.**
Messages returned to callers don't include stack traces, internal paths,
database schemas, or user data. Internal details stay internal.

## Should

**Secrets travel in request bodies or headers, never in URLs.**
A URL is copied into places its sender does not control: HTTP libraries' debug
logs and error messages, proxies, and the receiving service's access logs. A
token, key or password in a query string reaches all of them, and redaction
inside the process reaches none of the copies outside it. The exception is a
provider that accepts the secret nowhere else, and that exception is recorded
where the call is made.

**File access is constrained.**
File reads and writes are restricted to expected paths. Path traversal
sequences are rejected or fully resolved before use.

**External dependencies come from trusted sources.**
New dependencies are well-maintained and reputable. Integrity is verified
via lockfiles or checksums.

**Changes to production are traceable to who made them and when.**
Deploys, configuration changes, permission grants and manual actions in a cloud
console each leave a record naming the person or identity and the time. The
platform's audit log is turned on and kept long enough to cover the gap between
a change and the failure it causes. When a system breaks with no deploy to
blame, this record is how a manual change is found.

## Consider

**Access follows least privilege.**
Code requests only the permissions it needs. Overly broad access — admin
where read-only suffices, write where read suffices — is worth flagging.

**Public and authenticated endpoints are rate-limited.**
Endpoints that accept unauthenticated or high-volume requests have explicit
rate limits. Application-level limits protect against abuse patterns that
bypass upstream infrastructure controls.

**State-mutating endpoints are protected against CSRF.**
Endpoints that accept browser sessions and change server state verify request
origin. A CSRF check missing from a session-authenticated mutation is an
exploitable vulnerability. Applies to cookie-authenticated web APIs and
form handlers; not to Bearer-token or API-key authenticated endpoints.

## In scope

- HTTP handlers and CLI argument parsing
- File I/O
- Authentication and authorization enforcement
- Secret handling
- Audit logging and production access configuration for the cloud project or account

## Out of scope

- Test code using known-safe fixture values
- Internal admin endpoints with documented, intentionally permissive access scope
