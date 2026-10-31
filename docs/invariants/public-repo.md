# Public repo

Facts about what this repository may contain, because it is public on GitHub.

- No file git would publish names a private value: an internal hostname or URL, a cloud project,
  dataset, table or cluster ID, a private repo or internal project, the Jira cloud ID, or a
  colleague or their GitHub handle. A file's path counts as much as its contents, and so do
  examples, test fixtures, comments and archived files. Names that are already public, such as the
  employer, its GitHub org, the tools it uses and the work email, are not private values.
- A value a tracked file needs lives in the ignored `private.env` at the repo root, as a
  `PRIVATE_*` key, and the tracked file reads it from the environment. `private.env.example` lists
  each key with a made-up value and a `# read by:` line naming what reads it. The one older ignored
  file, `tools/agents/config/skills/monitor-prs/team-repos.local`, holds the repos `monitor-prs`
  watches.
- Commit messages, issue text and pull request text follow the first point too. History written
  before #230 was not rewritten.
- Nothing checks these points. A check that held them needed more edge-case rules in bash than a
  leak has cost so far, so the rule is kept by whoever writes a file. A check could come with the
  move of the repo's scripts to Python (#203).
