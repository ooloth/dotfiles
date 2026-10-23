# Skills

Facts about the shared skills in `tools/agents/config/skills/`, which `~/.claude/skills` and
`~/.agents/skills` both link to, so every agent session on the machine reads the same files.

- No file in a shared skill names a fixed path in a shared temp directory, such as
  `/tmp/changes.patch`. Two sessions running the same skill at once would read and write the same
  file, so one could stage the other's hunks or post the other's PR body. A skill that needs a
  scratch file gets a new directory from `mktemp -d` each time and uses the path it prints. The
  session scratchpad is not an alternative, because only Claude Code has one.
  `tools/agents/check-skills.py` checks every file in every skill that git does not ignore, from
  `scripts/checks/linting.bash`. The third-party skills synced into `skills/synced/` are gitignored,
  so it does not check them.
