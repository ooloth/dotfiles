---
name: use-youtube
description: Get a YouTube video's transcript, description and chapters as text. Read before fetching anything from YouTube, because yt-dlp's subtitle download is refused with HTTP 429 and a page fetch returns only the title.
---

## Transcript

`uv run ~/.claude/skills/use-youtube/scripts/transcript.py <url-or-video-id> > <file>` writes the
transcript as plain text, preferring English and falling back to any language. It exits non-zero
with a message on stderr when the video has none. Write it to a file in a folder from `mktemp -d`
and read the file, because a talk's transcript runs to tens of thousands of characters.

An auto-generated transcript mangles names: one talk's product came out as "Grokbot", "Graph Bot"
and "Gulp bot". Check every name against the description before you repeat it.

## Title, description and chapters

These work when subtitles are refused:

```
yt-dlp --skip-download --print "%(title)s | %(channel)s | %(duration_string)s | %(upload_date)s" <url>
yt-dlp --skip-download --print description <url>
```

The description often holds chapter timestamps and links to what the video cites.

## Don't

- Don't fetch the watch page with WebFetch. It returns the title and site navigation, not the
  description or the transcript.
- Don't download subtitles with `yt-dlp --write-auto-subs`. YouTube refuses it with HTTP 429, and
  retrying with other player clients did not help.
