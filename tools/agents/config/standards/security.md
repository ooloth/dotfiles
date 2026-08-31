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
messages, or stack traces.

**Authentication and authorization are enforced.**
Every protected route or operation verifies identity and permission before
proceeding. Auth checks are not bypassable by omitting a parameter or header.

**Errors don't leak sensitive information.**
Messages returned to callers don't include stack traces, internal paths,
database schemas, or user data. Internal details stay internal.

## Should

**File access is constrained.**
File reads and writes are restricted to expected paths. Path traversal
sequences are rejected or fully resolved before use.

**External dependencies come from trusted sources.**
New dependencies are well-maintained and reputable. Integrity is verified
via lockfiles or checksums.

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

## Out of scope

- Test code using known-safe fixture values
- Internal admin endpoints with documented, intentionally permissive access scope
