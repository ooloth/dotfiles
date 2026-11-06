# agents

Config shared by every coding agent, rather than owned by one of them.

Not a tool — nothing here installs a binary. `tools/claude/`, `tools/codex/`,
`tools/gemini/` and `tools/pi/` each install and configure their own harness;
this folder holds what they all read. Amp reads it too, in an orb, where
`tools/amp/workspace-resume.bash` links `~/.agents/skills` and
`~/.agents/standards` into it.

`config/standards/` is linked to both `~/.claude/standards` and
`~/.agents/standards`, so any harness can load it.

`config/skills/` is linked to both `~/.claude/skills` and
`~/.agents/skills`, so any harness can load it.

`check-skills.py` checks every skill in `config/skills/` that git does not ignore against
`docs/invariants/skills.md`, from `scripts/checks/linting.bash`. Its tests are in `tests/`.
