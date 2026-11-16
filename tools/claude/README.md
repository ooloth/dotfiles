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
