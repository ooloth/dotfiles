# claude

Claude Code, installed by `Brewfile` and configured from `config/`, where `link.bash` links the
global `CLAUDE.md`, `settings.json` and the subagent definitions into `~/.claude/`. The skills and
standards every session loads come from `tools/agents/config/` instead.

## Starting a session

`cc` starts Claude Code with this machine's permission mode, told where the repos related to the
current one are cloned, and `ccc` continues the last session. Both run `cc.bash`, whose header says
what it passes. On the work laptop each start first runs `auth`, which logs in to any work tool
whose credentials have expired.

## The status line

`settings.json` runs `statusline.py` by its path in this repo. It shows the location and git state
on the left, and the model, the context used and the subscription's 5-hour and 7-day limits on the
right. `CONTRIBUTING.md` says how to try a change to it by hand.

## Replaying planning

`replay plan <owner/repo#n> --run <k>` runs the unattended planning skill on a ticket I already
planned by hand, as a headless session in a sandbox that can't post or push and sees the repo only
as it stood when planning began. A short canary session first checks that the sandbox refuses two
forbidden reads, three forbidden writes and a forbidden connection, each with its fence's own
message, that a write in scratch and a `gh` call work, that no hook runs, and that the repo's own
`CLAUDE.md` loads, and the replay runs only if all of that holds. It writes a folder under
`${XDG_STATE_HOME:-~/.local/state}/replays/` holding the replay's plan or escalation, my own
approach and design, the session's usage, an audit of what the sandbox refused, and a `grade.md` to
fill in. `replay grades` summarizes the grades so far. `replay.py`'s docstring says what the sandbox
allows, and [ooloth/dotfiles#269](https://github.com/ooloth/dotfiles/issues/269) records why it
works this way.
