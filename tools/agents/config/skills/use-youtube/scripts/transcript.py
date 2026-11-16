#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "youtube-transcript-api>=1,<2",
# ]
# ///
"""Print the best available transcript for a YouTube video as plain text.

Usage: transcript.py <youtube-url-or-video-id>

Prefers an English transcript (manual or auto-generated); falls back to
whatever language is available. Exits non-zero with a message on stderr
if no transcript exists at all.
"""

import re
import sys

from youtube_transcript_api import (
    NoTranscriptFound,
    TranscriptsDisabled,
    VideoUnavailable,
    YouTubeTranscriptApi,
)

VIDEO_ID_PATTERN = re.compile(
    r"(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)([A-Za-z0-9_-]{11})"
)
BARE_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{11}$")


def extract_video_id(url_or_id: str) -> str:
    if BARE_ID_PATTERN.match(url_or_id):
        return url_or_id
    match = VIDEO_ID_PATTERN.search(url_or_id)
    if match:
        return match.group(1)
    raise ValueError(f"Could not find a YouTube video ID in: {url_or_id}")


def fetch_transcript_text(video_id: str) -> str:
    api = YouTubeTranscriptApi()
    transcript_list = api.list(video_id)

    try:
        transcript = transcript_list.find_transcript(["en"])
    except NoTranscriptFound:
        available = [t.language_code for t in transcript_list]
        if not available:
            raise
        transcript = transcript_list.find_transcript(available)

    fetched = transcript.fetch()
    return " ".join(snippet.text for snippet in fetched)


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: transcript.py <youtube-url-or-video-id>", file=sys.stderr)
        sys.exit(1)

    arg = sys.argv[1]

    try:
        video_id = extract_video_id(arg)
        text = fetch_transcript_text(video_id)
    except ValueError as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
    except TranscriptsDisabled:
        print(f"Transcripts are disabled for video: {arg}", file=sys.stderr)
        sys.exit(1)
    except NoTranscriptFound:
        print(f"No transcript is available in any language for video: {arg}", file=sys.stderr)
        sys.exit(1)
    except VideoUnavailable:
        print(f"Video unavailable: {arg}", file=sys.stderr)
        sys.exit(1)

    print(text)


if __name__ == "__main__":
    main()
