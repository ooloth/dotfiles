# Terraform

Infrastructure code is correct when the configuration is the single source of
truth for what exists, a reviewer can predict the effect of applying it, and
the parts the tool genuinely cannot manage are named rather than left implied.

## Must

**Secret values are not written into configuration.**
A password, key, or token appears as a reference to a secret manager or a
runtime input, never as a literal or a `default` in `variables.tf`. State
records resolved values regardless, so state is treated as a secret store in
its own right — never committed, never printed in CI logs.

**Plan output is read before apply, and destroys are noticed.**
Deleting a resource block destroys the resource. Renaming a resource address
destroys and recreates it unless a `moved` block accompanies the rename. A plan
containing an unexpected `destroy` or `replace` is a stop, not a formality.

**Resources under management are not modified out of band.**
A console click or `gcloud`/`aws` CLI mutation of a managed resource is drift:
the next apply silently reverts it, or fails. When something must be done by
hand, it is done to a resource Terraform does not own, or the configuration is
updated to match.

## Should

**IAM grants are the narrowest role that satisfies the need.**
When a predefined role is materially wider than the permissions actually
required, the least-privilege form is a custom role naming those permissions.
Reaching for the broader predefined role is a decision that gets justified in a
comment, not a default.

**Temporary access is time-boxed and then deleted.**
A grant issued for one piece of work carries an expiry condition. Expiry does
not remove the resource — past the timestamp the binding grants nothing but
remains in state and in every plan, implying access that no longer exists. The
resource is deleted once the work it unblocked is done, and the comment on it
says so.

**Per-environment resources are separate resources, not widened ones.**
Extending an existing grant, firewall rule, or binding to cover a second
environment couples their lifecycles: a constraint chosen for one silently
governs the other. Each environment gets its own copy with its own parameters.

**What Terraform cannot reach is documented where it would have lived.**
Some state is outside the provider's reach — a `GRANT` on a private-IP
database, a value only a human can obtain, a step requiring network access the
CI runner lacks. The configuration says so at the point where a reader expects
the resource, names the constraint that forces it, and links to the procedure.
Silence reads as an oversight.

**The permission system Terraform manages is not the only one.**
Cloud IAM governs whether a principal can reach a resource; the resource's own
authorization model governs what it may then do. Terraform typically manages
only the first. A connection that succeeds and then denies every operation is
this gap, and the second system's setup is accounted for somewhere.

**Identifiers come from module outputs and data sources, not literals.**
Project IDs, subnet self-links, and service account emails are referenced
through the resource or module that produces them. A hardcoded ID survives the
rebuild of the thing it names.

**`for_each` is used over `count` for sets of named things.**
Removing an element from a `count` list reindexes and recreates everything
after it. `for_each` keys resources by a stable identifier, so removal affects
only that one.

**Provider and module versions are pinned.**
An unpinned provider means a plan's output depends on when it ran. Constraints
are explicit and the lockfile is committed.

**Precedent in the repository is followed, and departures are flagged.**
Before introducing a construct, the repository is searched for how the same
problem was solved elsewhere. A first-of-its-kind pattern is not disqualifying,
but it is called out for review rather than presented as routine.

**Comments explain the constraint, not the syntax.**
The valuable comment records why the resource has this shape — what was tried,
what forced the compromise, what a future reader would otherwise undo. The
resource type and arguments already say what it does.

**`fmt` and `validate` run before commit, and unrelated drift stays out.**
Pre-existing formatting drift in a file is not folded into a change with its
own review stakes — a security or privilege diff should contain nothing but the
change being reviewed.

## Consider

**A repeated shape becomes a module.**
Three near-identical copies of the same resource group are a module waiting to
be extracted, provided the copies are genuinely the same thing rather than
coincidentally similar.

**State is split so blast radius is bounded.**
One state file spanning every environment means one bad apply can affect all of
them. Splitting by environment or by lifecycle bounds the damage and shortens
plan times.

**Resources carry labels that make cost and ownership attributable.**
An owner, environment, and cost-centre label turns an unexplained line item
into a question with an addressee.

## In scope

- `.tf`, `.tfvars`, and lockfiles
- CI/CD configuration that runs plan or apply
- Runbooks and READMEs describing manual steps adjacent to managed infrastructure

## Out of scope

- Generated files under `.terraform/`
- Vendored upstream modules not maintained in this repository
