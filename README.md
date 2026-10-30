# My dotfiles 🦸

A highly opinionated development environment for macOS, including shell, editor and tool
configuration plus the agent skills and engineering workflows I use every day.

_**Disclaimer:** I update these configurations often as my preferences change. I recommend you
treat this repo as inspiration and fork and customize it if you'd like stability._

## 🤖 Agent-assisted development

I've been experimenting with coding agents as a way to make good engineering practices explicit and
repeatable, rather than just using them to generate code. Most of what's here exists because an
agent failed in a specific way and the fix had to be something that runs, not something I remember.
The same rules keep surfacing in different places: three separate skills independently ask what
you'd do to observe a change if the test suite didn't exist.

It all lives in [`tools/agents/config/`](./tools/agents/config), symlinked into both `~/.claude/`
and `~/.agents/` so it belongs to no single harness and any agent that reads the shared location
gets the same files.

### Standards

[The standards library](./tools/agents/config/standards/README.md) is 29 files the rest of this
reads. Each standard is phrased as a claim about the code rather than an instruction to the agent:
"Errors are handled at the level with enough context to act," not "Handle errors at the right
level." That single rule is what lets one file serve three jobs unchanged, since a writing skill
reads it as "produce this," a review skill as "check for this," and a scan as "find violations of
this." Each is graded Must, Should or Consider, and only Must holds unconditionally.

[uphold-standards](./tools/agents/config/skills/uphold-standards/SKILL.md) is how they get loaded,
and it's short on purpose. An instruction that governs an act has to load at that act, not at the
start of a session, because memory of a rule decays and work built on the paraphrase looks
compliant while breaking it. So the trigger is phrased as recurring: a session making four changes
loads the standards four times.

### Deciding

[discuss](./tools/agents/config/skills/discuss/SKILL.md) explores a problem and decides what to do
without changing anything. Every claim is either verified, with the check named, or tagged as an
assumption. Where my description of the system and the code disagree, that becomes an open question
rather than being quietly resolved in either direction.

[design](./tools/agents/config/skills/design/SKILL.md) works out the type progression, assertion
plan and test plan before anything is implemented. A constraint that can be asserted at runtime is
asserted _and_ tested, never one instead of the other: a test covers the inputs its author
imagined, an assertion covers the inputs production supplies.

[next](./tools/agents/config/skills/next/SKILL.md) recommends one to three things to work on next in
any repo and stops. It ranks by cost of delay, not by how long the work would take, and it learns
each repo's trackers and conventions from that repo's own docs rather than from a copy of the skill
kept per repo. [scan-ideas](./tools/agents/config/skills/scan-ideas/SKILL.md) applies the same rule
to the whole backlog and lists what has gone stale.

### Reviewing

[review-code](./tools/agents/config/skills/review-code/SKILL.md) runs eleven specialised reviewers
in parallel, then assumes they're wrong. Every claim about library behaviour, API guarantees or
numbers is checked against the installed code before it reaches me, and a claim that fails is
struck rather than softened. Findings are labelled introduced or pre-existing by reading the base
ref, not by impression.

[review-converge](./tools/agents/config/skills/review-converge/SKILL.md) reviews and fixes in rounds
until nothing auto-fixable is left, escalating only the decisions that need an author, and never
committing. It spawns one fix agent per round rather than one per file, because a fix and the test
guarding it are coupled, and splitting by file produces a serial chain of handoffs that looks like
parallelism and isn't.

[review-pr-comments-converge](./tools/agents/config/skills/review-pr-comments-converge/SKILL.md)
does the same for reviewer feedback, and doesn't take the reviewer's word for it either: each
comment is checked against the current code and marked valid, stale or mistaken before anything
acts on it. What gets fixed automatically and what gets escalated turns on one question, does
applying this require the author to make a choice.

[prove-it-works](./tools/agents/config/skills/prove-it-works/SKILL.md) proves or disproves a claim
about the running system, given one sentence naming the claim or a PR, commit or URL. It sets the
bar for proof and leaves the method to the model: every observation's raw output is saved and every
quote points to its file, so a reader who wasn't there can check each verdict. The test suite
doesn't count as any part of the proof.

[merge-and-verify](./tools/agents/config/skills/merge-and-verify/SKILL.md) watches a merged PR's
rollout and then proves its effect with prove-it-works. It reads the deploy chain from the repo's
docs, counts the change as serving only when the live artifact's commit contains the merge, and
checks every five minutes or so in a fresh turn until the watch reaches one of its named endings.

[monitor-prs](./tools/agents/config/skills/monitor-prs/SKILL.md) checks every fifteen minutes or so
for the pull requests where it's my move, and says why, using the same rules hub's daemon does. Each
check reads one snapshot from GitHub and decides from that alone, so two checks of the same state
agree. A truncated or failed fetch is reported as such rather than as nothing waiting. It is
read-only for now; preparing the next step for each turn comes later.

[wrap-up](./tools/agents/config/skills/wrap-up/SKILL.md) ends a session by finding what would
mislead the next agent. Every action the session raised gets exactly one status (done, deferred,
dropped or open) with evidence for it, so a request made in passing can't quietly disappear. It
reads the whole open backlog for tickets the session's work made false or finished. A cold reader
given only the repo path reports what it would do next and what told it to. It passes only if it
picks the right thing for the right reason, because the signal it followed is the one the next
agent will follow too.

### Writing

[write-pr-description](./tools/agents/config/skills/write-pr-description/SKILL.md) writes the
verification checklist a reviewer actually needs, which means never citing the test suite or CI, and
cutting any step that can't run on a laptop before merging. The bar is what a skeptic would demand
you prove without running tests or deploying.

[write-ticket-description](./tools/agents/config/skills/write-ticket-description/SKILL.md) covers
issues and epics, including a coverage table that maps each externally-defined requirement to the
sub-issue satisfying it, so "did we miss anything" is a lookup rather than a judgment call.

[write-progress-update](./tools/agents/config/skills/write-progress-update/SKILL.md) drafts a short
Slack update on what a work project finished and what comes next, gathered from Jira, GitHub and
Slack since the last update. It shows the candidate items with their sources first, flags anything
from a DM or private channel, and saves the result as a Slack draft that it never sends.

They're opinionated and evolving because they're mostly an attempt to encode how I already like to
work.

## What's Included

```
docs/          # decisions, invariants, open questions, repo-specific standards
features/      # workflows that span tools: setup, install, update, check, test, run
tools/         # one self-contained folder per tool, each owning its own
               # install, config, symlinks and update logic
├── agents/    # config shared by every coding agent: the standards library and skills
├── claude/    # Claude Code harness: CLAUDE.md, settings, subagents, routines
└── ...        # bash, git, neovim, tmux, zsh and the rest
```

## Prerequisites

1. Connect to the internet
2. Sign into iCloud in System Preferences (required for App Store installations via `mas`)
3. Install Xcode Command Line Tools:
   ```sh
   xcode-select --install
   ```
4. Update macOS:
   ```sh
   sudo softwareupdate --install --all --restart
   ```

## Installation

```sh
curl -s https://raw.githubusercontent.com/ooloth/dotfiles/main/features/setup/setup.zsh | zsh
```

This will:

1. Clone this repository to `~/Repos/ooloth/dotfiles`
2. Run all installation scripts in sequence
3. Set up symlinks for all configurations
4. Configure macOS system preferences

## Checking

```sh
dcheck        # verify symlinks, tools, the agent shell and feature aliases
```

`dcheck` is a read-only health check. It reports `OK`, `MISSING`, or
`WRONG TARGET` for every managed symlink and confirms that critical
tools are installed. It also starts an interactive zsh with and without
`CLAUDECODE` set, and confirms that the agent shell has no aliases and no
function named like a command, while your own shell keeps its aliases.
Last, it confirms each feature's aliases run that feature's own scripts.
Exits nonzero if anything is wrong. `u` runs it after a full update.

## Updating

```sh
u             # update everything, then run dcheck
u "homebrew"  # update one tool
symlinks      # update symlinks
```

The `u` function runs all updates and reloads your shell. Before updating anything, it checks
each tool's prerequisites, such as the network or a running Docker daemon, and stops within a few
seconds if one is missing, saying which tool needs it and how to fix it.

## Contributing

I'm not accepting pull requests, but please feel free to...

- Open issues to discuss bugs, questions or suggestions
- Fork and customize this project however you like
- Demonstrate improvement opportunities using your fork

## Inspiration

- [Dotfiles community](https://dotfiles.github.io/)
- [Nick Nisi's dotfiles](https://github.com/nicknisi/dotfiles)
- The many developers who share their configurations publicly
