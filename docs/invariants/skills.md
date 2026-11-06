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
- A script in a shared skill that opens a Claude Code tab passes `--unattended` to the Rex launcher,
  so the session starts in auto mode, never in bypass mode, whatever the machine. Nobody watches a
  session a script starts, and it reads text other people wrote. A tab an agent opens from a skill's
  instructions while the user is at the keyboard needs no flag. `tools/agents/check-skills.py`
  fails a `.py`, `.bash` or `.sh` file, other than a `test_*` file, that names `claude-tab.bash`
  with no `--unattended` outside a comment.
- Only the `create-pr` skill runs `gh pr create`. It writes the description with
  `write-pr-description`, opens the draft and links it on its Jira, Linear or Monday ticket, and an
  instruction file that opens a PR itself skips all three. No other file in a skill, and no file in
  `tools/claude/config/` (`CLAUDE.md`, the agents and the routines), names the command.
  `use-gh/SKILL.md` may, because it only lists the commands that take `--body-file`.
  `tools/agents/check-skills.py` checks every file git does not ignore in both places, from
  `scripts/checks/linting.bash`.
- A skill whose frontmatter has no `context: fork` keeps the session that loads it on Opus at
  `high` effort or above: it sets `model:` only to the alias `opus` or to `inherit`, and `effort:`
  only to `high`, `xhigh` or `max`. Without `context: fork`, both apply to that session for the
  rest of the turn ([skills frontmatter reference](https://code.claude.com/docs/en/skills), read
  2026-11-06), so a cheaper model or a lower effort would do the rest of the turn's work. A pin of
  `high` still lowers a session running at `xhigh` or `max` for that turn; the floor is `high`, not
  the session's own level. A skill that wants a cheaper model for mechanical work names it for the
  subagent it launches. `tools/agents/check-skills.py` checks the frontmatter of every
  `skills/<name>/SKILL.md` that git does not ignore, from `scripts/checks/linting.bash`. It does
  not check the gitignored skills in `skills/synced/` or the project skills in `.claude/skills/`.
