# claude

Claude Code, installed by `Brewfile` and configured from `config/`, where `link.bash` links the
global `CLAUDE.md`, `settings.json` and the subagent definitions into `~/.claude/`. The skills and
standards every session loads come from `tools/agents/config/` instead.

## Starting a session

`cc` starts Claude Code with this machine's permission mode, told where the repos related to the
current one are cloned, and `ccc` continues the last session. Both run `cc.bash`, whose header says
what it passes. On the work laptop each start first runs `auth`, which logs in to any work tool
whose credentials have expired, except a start with `--unattended`, where nobody is there to
finish a login. A caller can pass its own `--permission-mode` and `--append-system-prompt`; the
header says how `cc.bash` treats each.

## The status line

`settings.json` runs `statusline.py` by its path in this repo. It shows the location and git state
on the left, and the model, the context used and the subscription's 5-hour and 7-day limits on the
right. `CONTRIBUTING.md` says how to try a change to it by hand.

## Moving sessions to Vertex AI

On the work laptop, every session `cc.bash` starts (`cc`, `ccc`, `cc-vertex` and Rex tabs) can use
Vertex AI instead of the subscription, so work can go on when the subscription's usage limit is
reached. That needs `PRIVATE_VERTEX_PROJECT` in `private.env`. A session started another way, or
without it, has no Vertex AI project and fails while sessions are on Vertex AI.
`CLAUDE_CODE_USE_VERTEX` in the `env` block of `settings.json` is the switch: `"1"` means Vertex AI
and `""` the subscription. Claude Code reloads the file in every running session, so they all move
together, from their next prompt.

`provider_switch.py` keeps which one sessions should use in `~/.local/state/claude/provider.json`,
with the time they move back from Vertex AI. Two things move sessions there on their own:

- **The status line,** when the 5-hour or weekly window it reports reaches 100%, until that window
  resets.
- **The `StopFailure` hook in `settings.json`,** when a turn fails with error `rate_limit`, whatever
  Claude Code's wording. The next prompt then goes to Vertex AI. A wording in `LIMIT_MESSAGES` keeps
  them there until that window resets, or for the window's full length when no reset time is
  recorded. Any other wording keeps them there until the latest reset of a window the status line
  last reported at 100%, or for `UNRECOGNISED_LIMIT_S` when there is none. A session already on
  Vertex AI, such as one `cc-vertex` started, moves nothing, because its 429 comes from Vertex AI
  itself.

Wording the switch doesn't know, from a subscription session's rate limit, is kept with when it was
seen, until newer unknown wording replaces it. `cc-switch` shows it until `LIMIT_MESSAGES` gains it,
so it can be added there.

While sessions are on Vertex AI, a used-up window that a status line reports and that resets after
their stay ends extends the stay to that reset. A session running on Vertex AI from its start
reports no usage windows, so this needs a session whose status line still shows the window. The
status line applies the state to `settings.json` on every refresh, moves sessions back once the
time passes, and shows `Vertex AI until <time>` meanwhile. Run `! cc-switch` in a session to see
which one they use, `! cc-switch vertex` to move them until the 5-hour limit resets, or
`! cc-switch subscription` to move them back. Moved back while a limit is still used up, they stay
on the subscription until it resets, with neither trigger moving them, and the status line shows
`subscription until <time>`.

`cc-vertex` starts a single session that stays on Vertex AI whatever the switch says. A commit
must never hold the switch at `"1"`, since personal Macs have no Vertex AI project.
`tests/test_settings.py` fails when the last commit holds it, so it catches one on the next check
run after the commit, not before.
