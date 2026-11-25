# Security

Security belongs to safety: a system is secure when nobody it has not authorised can make it act,
read what it holds, or stop it serving others. Its performance and experience matter too, because a
check that is slow or awkward is the one someone turns off. At its maximum:

- **Safety:** nothing from outside the system makes it do what its own code did not intend. Every
  protected action is taken only by an identity allowed to take it on that particular resource, a
  secret reaches only the process that uses it, and every refused attempt and every change to
  production leaves a record of who and when.
- **Performance:** being secure costs a legitimate user no wait beyond the checks the trust decision
  needs, and no input an outsider sends makes the system spend more than a bounded amount of work
  on it.
- **Experience:** the safe way is the default way. A developer gets escaping, parameterised queries
  and secret handling without remembering a step, and a reviewer can see in the code where untrusted
  input enters and where each permission is checked.

## Must

**Inputs are validated at system boundaries.**
All data entering the system, such as a request, a command-line argument, an uploaded file, an
environment variable or another service's response, is validated before use. Validation happens at
the boundary, not deep in business logic. Validation includes size. An input an outsider can make
large, such as a request body or the response from a URL a caller chose, has a size limit, set by
the code or by the framework's default, that applies before the system reads it whole. An input
whose processing cost grows faster than its length is capped before that processing, or handled by
a method whose worst case is bounded ("Algorithmic complexity is justified" in `performance.md`).
A compressed input's limit applies to what it expands to as well as to what arrives.

**Injection is not possible.**
Input never reaches an interpreter as code, and never chooses a file or address the system was not
meant to open. Each interpreter it reaches gets it through a form that keeps data apart from code,
such as a database query that takes values as parameters, a command run from a list of arguments
rather than a shell string, HTML output that is escaped, a URL whose parameters are encoded, and a
deserialiser that cannot construct arbitrary objects. A path built from input resolves inside the
directory meant for it before it is opened, and a URL the server fetches on a caller's behalf
reaches only the hosts it is meant to reach. Escaping is a property of the rendering approach rather
than a step someone remembers, so the only way to skip it is an explicit opt-out that shows in the
code.

**Text from an untrusted source cannot direct an action its author is not allowed to take.**
A model that reads text, such as a web page, an issue comment or an email, can follow instructions
written in it, and no escaping prevents that. So the limit lies in what the model can do while that
text is in its context: it holds only the permissions the text's author already has, or each action
outside them waits for a person to approve it. A session that holds private data, reads untrusted
text and can send data out has everything a leak needs, so no session holds all three unless each
action that sends data out waits for a person's approval.

**Secrets are not hardcoded, logged or shipped to anyone else.**
Credentials, API keys, tokens and passwords reach the system when it runs, from a secret store or
from the environment it is started with. No secret, whether the system's own or one a caller
sends, appears in source code, in the logs, error messages and stack traces the system writes, or
in anything handed to someone else, such as a browser bundle, a mobile app or a container image
layer. This includes local development: a file of real values inside the project's directory, such
as an ignored env file, does not meet this, because only an ignore rule keeps it out of the
repository, and one wrong rule or one forced add commits it. Where a committed file describes
what the environment needs, it holds _references_ to a secret store rather than the values
themselves, so committing it is harmless by construction rather than by vigilance.

**Every protected operation checks identity, and permission for the resource it touches, before it
proceeds.**
A caller allowed to read their own record cannot read another's by changing an identifier in the
request. Auth checks are not bypassable by omitting a parameter or header, or by skipping a step of
a sign-in that has several, such as a second factor. A check that cannot reach an answer, such as
one whose permission service times out, refuses.

**Errors don't leak sensitive information.**
Messages returned to callers don't include sensitive details, such as stack traces, internal paths,
database schemas, user data, or whether an account exists. A sign-in or password reset gives the
same answer for an unknown account as for a wrong password, and does the same work for both, so
neither the message nor the time it takes shows whether an account exists.

**Passwords, tokens and encryption use primitives built for the purpose.**
A stored password, or any other secret short enough to guess, is hashed with a function designed to
be slow and salted per value, never with a general-purpose hash or reversible encryption. A long
random token can be stored under a fast hash, because nobody can guess it to test against the hash.
A token, one-time code, session identifier or key comes from the platform's cryptographically
secure random source rather than a general-purpose one. A secret is compared in time that does not
depend on where the inputs differ. Encryption and signing come from a maintained library's
high-level interface rather than being assembled from lower-level pieces.

**Connections verify the identity of the server they reach.**
A client connecting over TLS checks the server's certificate and host name, so nobody between them
can read or change what passes. Verification is not turned off, in code or by an environment
setting, to get past a certificate error: a development server with its own certificate is trusted
by adding that certificate, which keeps verification on. Credentials travel only over connections
verified this way.

**A state-changing request authenticated by a browser cookie is shown to come from the site's own
pages.**
A browser attaches cookies to requests that other sites trigger, so a cookie alone does not show
that the user meant the request. An endpoint that accepts a session cookie and changes state
confirms where the request came from, such as by a token the page embeds or a check of the request's
origin. A cookie setting that stops the browser sending the cookie on requests other sites start
adds a second layer but is not enough alone, because the browser counts every subdomain of the same
registered domain as the same site. An endpoint authenticated by a credential the client attaches
itself, such as a bearer token or an API key, is outside this claim, because a browser never
attaches one on its own.

**A secret in an HTTP request travels in its body or a header, and in its URL only where it can
travel nowhere else.**
A URL is copied into places its sender does not control, such as an HTTP library's debug logs and
error messages, a proxy, browser history and the receiving service's access logs. A token, key or
password in a URL reaches all of them, and redaction inside the process reaches none of the copies
outside it. Two cases can travel nowhere else. One is a provider that accepts the secret only in the
query string, which a comment where the URL is built says, citing the provider's documentation. The
other is a link whose token is itself the credential, such as a password-reset link or a share link,
because the link is what a person clicks or passes on. A reset link's token stops working after its
first use, and a share link's can be revoked. An API that takes a secret only in its URL breaks
this for every caller.

## Should

**A command gets a secret from a store when it runs, not as a literal or an exported variable.**
A secret typed into a command is kept by shell history, terminal scrollback and anything that
records the session, and from there it reaches backups and whoever searches them. A variable
exported in a shell, or set for a whole job, or for a CI step that runs more than the command that
needs it, reaches every process started under it, including ones that print their environment in an
error report. Reading the secret from a secret store inside the command hands it to that one
process. Where the tool can read the secret from its environment, a file or standard input, the
command passes it that way, as in `TOKEN="$(<store> read <name>)" tool`, because an argument is
visible to other users on the machine in the process list while the command runs. Where the tool
takes the secret only as an argument, as in `tool --token "$(<store> read <name>)"`, and also writes
its own arguments to a log file, such as a cloud provider's command-line tool that records every
command it runs, the command turns that file logging off.

**Session cookies are hidden from page scripts, sent only over HTTPS and replaced at sign-in.**
A cookie that carries a session, or a credential that restores one such as a remember-me token, is
marked so that scripts on the page cannot read it and the browser sends it only over an encrypted
connection. A script injected into the page then cannot copy the session out, and nobody watching
the network sees it. Sign-in issues a new session identifier, and so does each later step that
widens what the session may do, such as a second factor, so an identifier an attacker planted in the
browser beforehand never gains those rights.

**An endpoint that checks a guessable credential limits repeated failed attempts.**
Checking a password, or a short code such as one sent for a second factor or a password reset, is
limited in failed attempts per account and per source. Without a limit, a password or a six-digit
code is found by trying candidates until one works. A long random token or key is outside this
claim, because trying candidates cannot find one.

**Access follows least privilege.**
Each identity, such as a service account, an API token, a deploy key or the set of tools an agent
holds, has only the permissions its work needs, so a leak or a bug in it can do only that much harm.
Broader access, such as admin where read-only suffices or write where read suffices, gives a leak or
a bug more to damage.

**Refused sign-ins and denied permissions are recorded.**
Each rejected password or one-time code, each refused key or token that never expires, such as an
API key, and each denied permission check leaves a record of the account it named where there is
one, the source and the time, in an access-controlled audit store the system's operators read. An
attacker who is refused every time is still trying, and without the record the only sign of the
attempt is the one that succeeds. The record holds no credential the caller sent. A token that
expires, such as a session cookie, a short-lived access token or a share link, needs no record when
it is refused as unknown or expired, because ordinary expiry produces the same refusal.

**Changes to production are traceable to who made them and when.**
Each change to production, such as a deploy, a configuration change, a permission grant or a manual
action in a cloud console, leaves a record naming the person, or the service identity for an
automated change, and the time. The
platform's audit log is turned on and kept long enough to cover the gap between a change and the
failure it causes. When a system breaks with no deploy to blame, this record is how a manual change
is found.

## Consider

**A leaked credential can be revoked on its own and replaced without a code change.**
A credential that leaks stays useful to whoever holds it until it stops working. Where replacing it
means editing code and shipping a release, the gap between the leak and the fix is as long as that
takes. Where it can be revoked only by revoking every credential of its kind, such as by rotating
the key that signs them all, the fix logs out everyone, and where it cannot be revoked at all, the
gap lasts until it expires.

**Public endpoints are rate-limited.**
An endpoint that accepts unauthenticated or high-volume requests has an explicit rate limit, so one
caller cannot use up the capacity others need. A limit in the application covers abuse that passes
an upstream control, such as requests spread across many sources that each stay under a network
limit.

## In scope

- HTTP handlers and CLI argument parsing
- File I/O, and URLs the system fetches
- Authentication and authorization enforcement, sessions and cookies
- Secret handling, password storage, token generation and encryption
- Outbound connections
- Model calls that read text from outside the system while holding tools or private data
- Audit logging and production access configuration for the cloud project or account
- Shell commands, scripts and CI job configuration that handle secrets
- Setup docs that say where secrets go

## Out of scope

- Test code using known-safe fixture values
- The permission check on an internal admin endpoint whose permissive access is documented and
  intended
- Where dependencies come from and how their integrity is checked, which `dependencies.md` covers
