---
name: use-slack
description: Slack MCP gotchas that make a search return nothing with no error, a message render wrong, or a post notify people who should not hear from it. Read before every Slack tool call, reads included, because a bad post cannot be un-notified. Re-invoke each time.
---

# Using Slack

## Work only

Slack is for work only. On a machine where `$PRIVATE_SLACK_REPORT_CHANNEL` is unset, such as the
user's personal Macs, no Slack tool is called: a skill that would read Slack skips it and says so,
and a skill that would post shows the message in the terminal instead.

## Formatting a message

- The Slack MCP tools take standard markdown, not Slack's own markup: `**bold**`, `_italic_`,
  `[text](url)`. A single `*x*` renders as italic, not bold.
- A mention is `<@U…>` with the person's Slack user ID, which `slack_search_users` finds, or an
  existing `<@U…>` mention of them shows. Mention only people whose ID you have, and write anyone
  else's name without `@`.
- Every mention notifies that person, so a test message mentions only the user.

## Searching

- A search `in:` a channel name that does not exist returns "No results found", not an error. Find
  the channel with `slack_search_channels` first, and search it by the exact name or ID that
  returns. Seen 2026-11-21: a search `in:#team-eng` returned nothing because the channel was
  named `#team-engineering`.
- `slack_search_channels` searches only public channels unless `channel_types` is
  `public_channel,private_channel`.
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
  text and that destination, unless the skill posting it says invoking it approves that
  destination.
- Before posting to a channel the user did not name, read its topic and description with
  `slack_search_channels`. If they say that kind of message belongs elsewhere, tell the user
  instead of posting.
