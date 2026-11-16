"""Tests for transcript.py's reading of a video ID, the part that can go wrong without a network.

Most tests load the script in-process to call `extract_video_id`. One runs it as a subprocess on
input with no video ID, which exits before any request is made. One compares the dependency range
with the one `scripts/checks/tests.bash` installs.

Run with `bash scripts/checks/tests.bash` from the repo root, which installs what these tests need.
"""

import importlib.util
import re
import subprocess
import sys
from pathlib import Path

import pytest
from hypothesis import given
from hypothesis import strategies as st

SCRIPT = Path(__file__).with_name("transcript.py")
REPO = SCRIPT.parents[6]

spec = importlib.util.spec_from_file_location("transcript", SCRIPT)
assert spec is not None and spec.loader is not None
transcript = importlib.util.module_from_spec(spec)
spec.loader.exec_module(transcript)

video_ids = st.text(
    alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",
    min_size=11,
    max_size=11,
)

URL_FORMS = [
    "https://www.youtube.com/watch?v={id}",
    "https://youtube.com/watch?v={id}&t=42s",
    "https://www.youtube.com/watch?v={id}&list=PL123",
    "https://youtu.be/{id}",
    "https://youtu.be/{id}?si=abc",
    "https://www.youtube.com/shorts/{id}",
    "https://www.youtube.com/embed/{id}",
]


@pytest.mark.parametrize("form", URL_FORMS)
@given(video_id=video_ids)
def test_every_url_form_gives_back_its_video_id(form: str, video_id: str) -> None:
    assert transcript.extract_video_id(form.format(id=video_id)) == video_id


@given(video_id=video_ids)
def test_a_bare_video_id_is_returned_unchanged(video_id: str) -> None:
    assert transcript.extract_video_id(video_id) == video_id


@pytest.mark.parametrize(
    "text",
    ["", "not a video", "https://example.com/watch?v=O_zcc6Xl12g", "O_zcc6Xl12", "O_zcc6Xl12g!"],
)
def test_text_with_no_video_id_is_refused(text: str) -> None:
    with pytest.raises(ValueError, match="Could not find a YouTube video ID"):
        transcript.extract_video_id(text)


def test_the_script_exits_with_a_message_when_given_no_video_id() -> None:
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "not a video"],
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )
    assert result.returncode == 1
    assert "Could not find a YouTube video ID in: not a video" in result.stderr
    assert result.stdout == ""


def test_the_test_run_installs_the_range_the_script_declares() -> None:
    header = re.search(r'"youtube-transcript-api([^"]*)"', SCRIPT.read_text())
    runner = re.search(
        r"'youtube-transcript-api([^']*)'", (REPO / "scripts/checks/tests.bash").read_text()
    )
    assert header is not None and runner is not None
    assert header.group(1) == runner.group(1)
