# Public repo

Facts about what this repository may contain, because it is public on GitHub.

- No file git would publish names a private value: an internal hostname or URL, a cloud project,
  dataset, table or cluster ID, a private repo or internal project, the Jira cloud ID, or a
  colleague or their GitHub handle. A file's path counts as much as its contents, and so do
  examples, test fixtures, comments and archived files. Names that are already public, such as the
  employer, its GitHub org, the tools it uses and the work email, are not private values.
- A value a tracked file needs lives in the ignored `private.env` at the repo root, as a
  `PRIVATE_*` key, and the tracked file reads it from the environment. A private name that no
  tool reads goes in `PRIVATE_TERMS`, so the check below looks for it too. The one older ignored
  file, `tools/agents/config/skills/monitor-prs/team-repos.local`, holds the repos `monitor-prs`
  watches, and the check searches for its names only if they are also in `PRIVATE_TERMS`.
- `private.env.example` lists every `PRIVATE_*` name used outside a `tests/` folder, with a
  `# machines:` line naming the machines that need it (`air`, `mini`, `work`) and a `# read by:`
  line naming what reads it. Tests use made-up keys and values.
- `scripts/checks/private_values.py`, run from `scripts/checks/linting.bash`, checks the first and
  third points over every file git tracks or would track. Its terms are every word of every
  `PRIVATE_*` value, so a Mac without `private.env` fails the check. CI and Amp orbs have no
  private values, so there it skips the search and still checks the example.
- Commit messages, issue text and pull request text follow the first point too, and nothing checks
  them. History written before #230 was not rewritten.
