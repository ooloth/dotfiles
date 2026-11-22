---
name: use-slack
description: Slack MCP gotchas that make a search return nothing with no error, a message render wrong, or a post notify people who should not hear from it. Read before every Slack tool call, reads included, because a bad post cannot be un-notified. Re-invoke each time.
---

# Using Slack

## Work only

Slack is for work only. Before the first Slack call, reads included, run
`[ -n "${PRIVATE_SLACK_REPORT_CHANNEL:-}" ]`. Where it fails, because the variable is unset or
empty, as on the user's personal Macs, no Slack tool is called: a skill whose steps depend on Slack
says so and stops before its first step, and a message meant for Slack is shown in the terminal
instead.

The variable holds the ID of the user's own channel, which is meant to hold only the user, so a
draft posted there reaches nobody else. The mention check below confirms that before each draft
with mentions. The user copies the text from there into its destination.

## Formatting a message

- The Slack MCP tools take standard markdown, not Slack's own markup: `**bold**`, `_italic_`,
  `[text](url)`. A single `*x*` renders as italic, not bold.
- A mention is `<@U…>` with the person's Slack user ID, which `slack_search_users` finds, or an
  existing `<@U…>` mention of them shows. Mention only people whose ID you have, and write anyone
  else's name without `@`.
- A mention notifies that person in any channel they are in, so a test message mentions only the
  user. Before showing a draft with mentions that will go to the user's own channel, list its
  people with `slack_list_channel_members` (`response_format: concise`, which leaves out bots). If
  anyone but the user is there, write the names without `@` and tell the user why.

## Searching

- A search `in:` a channel name that does not exist returns "No results found", not an error. Find
  the channel with `slack_search_channels` first, and search it by the exact name or ID that
  returns. For example, a search `in:#team-x` returns nothing when the channel is `#team-x-eng`.
- `slack_search_channels` searches only public channels unless `channel_types` is
  `public_channel,private_channel`.
- `slack_search_public` never sees private channels or DMs, and returns nothing from them with no
  error. Searching those takes `slack_search_public_and_private`. Its description asks for the
  user's consent, and the user has given it for every channel and DM, so no search stops to ask.
- Message searches sort by relevance and return at most 20 results a page. A search for the latest
  message of some kind passes `sort: timestamp`, and a claim that none exists pages with `cursor`
  until it is empty.
- The user has two scratchpads, and nothing in either is ever a source: their DM to themselves,
  and their own channel, whose ID is in `$PRIVATE_SLACK_REPORT_CHANNEL`. Every message search
  excludes both, with `-in:<@U…>` (the user's own Slack user ID, which the Slack tools'
  descriptions state) and `-in:<#C…>` (that channel's ID). A skill that reads either for a reason
  of its own says so.
- Tell every subagent that calls a Slack tool to read this skill first.

## Drafts

- Slack keeps one draft per channel, and `slack_send_message_draft` can neither replace nor delete
  one. If a draft already exists where you would save, ask the user to delete it and save once they
  say they have. When the user may ask for a revision, tell them this before they need to.

## Posting

- Posting notifies people and cannot be undone. Each message needs the user's approval for that
  text and that destination, shown together before it is posted. The exception is a message the
  global `CLAUDE.md` says invoking a skill approves, such as `merge-and-verify`'s epilogue message.
- Write each message with the Write tool to a file in a new directory from `mktemp -d`, and show
  the user that file's text. Once they approve it, Read the file and pass that text as the message,
  rather than typing it again.
- Before posting to a channel the user did not name, other than their own channel, read its topic
  and description with `slack_search_channels`. If they say that kind of message belongs
  elsewhere, tell the user instead of posting.
