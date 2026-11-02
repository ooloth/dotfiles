"""Black-box tests for capture_window.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `osascript` on
PATH prints a window list from a fixture file, and a fake `screencapture` records its arguments and
writes an image (or fails, or writes nothing), so no test reads the real screen. That keeps every
property checkable in CI, where there is no screen to capture.

Run:
  uv run --with pytest --with hypothesis pytest \
    tools/agents/config/skills/prove-it-works/scripts/test_capture_window.py
"""

import json
import os
import subprocess
import sys
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

import pytest
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

SCRIPT = Path(__file__).with_name("capture_window.py")

FAKE_OSASCRIPT = """#!/usr/bin/env python3
import os, sys
if os.environ.get("FAKE_OSASCRIPT_FAIL"):
    print("execution error: not allowed", file=sys.stderr)
    sys.exit(1)
sys.stdout.write(open(os.environ["FAKE_WINDOWS"]).read())
"""

FAKE_SCREENCAPTURE = """#!/usr/bin/env python3
import json, os, sys
with open(os.environ["FAKE_LOG"], "a") as log:
    log.write(json.dumps(sys.argv[1:]) + "\\n")
mode = os.environ.get("FAKE_CAPTURE", "ok")
if mode == "fail":
    print("could not create image from window", file=sys.stderr)
    sys.exit(1)
if mode == "ok":
    open(sys.argv[-1], "wb").write(b"\\x89PNG fake image")
"""


@dataclass(frozen=True)
class Window:
    id: int
    owner: str
    title: str | None


@pytest.fixture(scope="module")
def stubs(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    """Write both fake tools once, in a folder made read-only so tests can't change them."""
    folder = tmp_path_factory.mktemp("stubs")
    for name, body in (("osascript", FAKE_OSASCRIPT), ("screencapture", FAKE_SCREENCAPTURE)):
        tool = folder / name
        tool.write_text(body)
        tool.chmod(0o755)
    folder.chmod(0o555)
    yield folder
    folder.chmod(0o755)


@dataclass(frozen=True)
class Run:
    code: int
    stdout: str
    stderr: str
    captures: list[list[str]]

    @property
    def output(self) -> str:
        return self.stdout + self.stderr


def run(
    root: Path,
    stubs: Path,
    windows: list[Window],
    *args: str,
    out: Path | None = None,
    **env: str,
) -> Run:
    """Run the script against `windows`, capturing into `out` (default: a new file under root)."""
    root.mkdir(parents=True, exist_ok=True)
    listing = root / "windows.json"
    listing.write_text(json.dumps([w.__dict__ for w in windows]))
    log = root / "capture.log"
    log.write_text("")
    target = out if out is not None else root / "evidence" / "shot.png"
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *args, "--out", str(target)],
        capture_output=True,
        text=True,
        env={
            **os.environ,
            "PATH": f"{stubs}{os.pathsep}{os.environ['PATH']}",
            "FAKE_WINDOWS": str(listing),
            "FAKE_LOG": str(log),
            **env,
        },
    )
    captures = [json.loads(line) for line in log.read_text().splitlines()]
    return Run(result.returncode, result.stdout, result.stderr, captures)


REX = Window(727, "Rex Beta", "Agent scaling options - Goals")
SAFARI = Window(139, "Safari", "Pricing - exe.dev")
MESSAGES = Window(620, "Messages", "A private contact")


# Matching the app name


def test_a_short_app_name_finds_the_app_whose_name_starts_with_it(
    tmp_path: Path, stubs: Path
) -> None:
    result = run(tmp_path, stubs, [SAFARI, REX], "--app", "Rex")
    assert result.code == 0, result.output
    assert result.captures == [["-o", "-x", "-l727", str(tmp_path / "evidence" / "shot.png")]]


def test_the_app_name_matches_in_any_case(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "rex beta")
    assert result.code == 0, result.output
    assert result.captures[0][2] == "-l727"


def test_a_name_inside_another_word_does_not_match(tmp_path: Path, stubs: Path) -> None:
    firefox = Window(5, "Firefox", "A page")
    result = run(tmp_path, stubs, [firefox], "--app", "fox")
    assert result.code == 1
    assert result.captures == []
    assert "No on-screen window of fox" in result.stderr


# Choosing one window


def test_several_windows_and_no_title_capture_nothing_and_list_only_that_apps_titles(
    tmp_path: Path, stubs: Path
) -> None:
    second = Window(728, "Rex Beta", "Another tab")
    result = run(tmp_path, stubs, [REX, MESSAGES, second], "--app", "Rex")
    assert result.code == 1
    assert result.captures == []
    assert "Agent scaling options - Goals" in result.stderr
    assert "Another tab" in result.stderr
    assert "--title" in result.stderr
    assert "Messages" not in result.output
    assert "A private contact" not in result.output


def test_a_title_that_narrows_to_one_window_captures_it(tmp_path: Path, stubs: Path) -> None:
    second = Window(728, "Rex Beta", "Another tab")
    result = run(tmp_path, stubs, [REX, second], "--app", "Rex", "--title", "another")
    assert result.code == 0, result.output
    assert result.captures[0][2] == "-l728"
    assert "728" in result.stdout


def test_a_title_that_matches_no_window_says_so(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex", "--title", "nothing like it")
    assert result.code == 1
    assert result.captures == []
    assert "No on-screen window of Rex" in result.stderr
    assert "nothing like it" in result.stderr


def test_hidden_titles_report_the_missing_screen_recording_permission(
    tmp_path: Path, stubs: Path
) -> None:
    hidden = [Window(727, "Rex Beta", None), Window(139, "Safari", None)]
    result = run(tmp_path, stubs, hidden, "--app", "Rex")
    assert result.code == 1
    assert result.captures == []
    assert "Screen Recording" in result.stderr


def test_an_untitled_window_is_captured_when_titles_are_visible(
    tmp_path: Path, stubs: Path
) -> None:
    untitled = Window(137, "Safari", "")
    result = run(tmp_path, stubs, [untitled, REX], "--app", "Safari")
    assert result.code == 0, result.output
    assert result.captures[0][2] == "-l137"


# Protecting evidence


def test_an_existing_output_file_is_refused_and_left_unchanged(tmp_path: Path, stubs: Path) -> None:
    existing = tmp_path / "evidence" / "shot.png"
    existing.parent.mkdir(parents=True)
    existing.write_bytes(b"earlier evidence")
    result = run(tmp_path, stubs, [REX], "--app", "Rex", out=existing)
    assert result.code == 1
    assert result.captures == []
    assert existing.read_bytes() == b"earlier evidence"
    assert "already exists" in result.stderr


def test_an_output_path_that_is_not_a_png_is_refused(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex", out=tmp_path / "shot.jpg")
    assert result.code != 0
    assert result.captures == []
    assert ".png" in result.stderr


# Failures at the boundaries


def test_osascript_failing_exits_with_a_sentence(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex", FAKE_OSASCRIPT_FAIL="1")
    assert result.code == 1
    assert result.captures == []
    assert "Could not list windows" in result.stderr
    assert "Traceback" not in result.stderr


def test_an_unexpected_window_list_exits_with_a_sentence_and_does_not_echo_it(
    tmp_path: Path, stubs: Path
) -> None:
    listing = tmp_path / "bad.json"
    listing.write_text('{"not": "a list", "secret": "A private contact"}')
    result = run(tmp_path, stubs, [], "--app", "Rex", FAKE_WINDOWS=str(listing))
    assert result.code == 1
    assert "unexpected window list" in result.stderr
    assert "A private contact" not in result.output
    assert "Traceback" not in result.stderr


def test_screencapture_failing_exits_with_a_sentence(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex", FAKE_CAPTURE="fail")
    assert result.code == 1
    assert "could not create image from window" in result.stderr
    assert "727" in result.stderr


def test_screencapture_succeeding_without_an_image_exits_with_a_sentence(
    tmp_path: Path, stubs: Path
) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex", FAKE_CAPTURE="empty")
    assert result.code == 1
    assert "no image" in result.stderr


def test_a_capture_reports_the_window_it_captured(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex")
    assert result.code == 0, result.output
    assert "727" in result.stdout
    assert "Rex Beta" in result.stdout
    assert "Agent scaling options - Goals" in result.stdout
    assert (tmp_path / "evidence" / "shot.png").read_bytes().startswith(b"\x89PNG")


# Properties over any window list

APPS = ["Rex", "Rex Beta", "Safari", "Mail"]
# Owners that contain an app name without being that app, so a loose match would catch them.
NEAR_MISSES = ["Rexy", "Apex Rex", "SafariDriver", "Mailbox", "Brex"]


@st.composite
def screens(draw: st.DrawFn) -> tuple[str, list[Window], str | None]:
    """An app to ask for, a window list mixing its windows with others, and an optional title.

    Every window that must not match gets a sentinel owner or title, so finding the sentinel in
    the output proves another app's window leaked.
    """
    app = draw(st.sampled_from(APPS))
    # Hidden titles end every run early, so they are drawn rarely, and short lists make a single
    # candidate (the case that gets captured) common.
    hidden = draw(st.sampled_from([False, False, False, True]))
    count = draw(st.integers(min_value=0, max_value=4))
    windows: list[Window] = []
    for n in range(count):
        kind = draw(st.sampled_from(["match", "other", "near"]))
        if kind == "match":
            owner = draw(st.sampled_from([app, app.upper(), f"{app} Beta"]))
            title = None if hidden else draw(st.sampled_from(["", f"tab {n}", "Goals"]))
        elif kind == "other":
            owner = f"Otherapp{n}"
            title = None if hidden else f"leak-{n}"
        else:
            owner = draw(st.sampled_from(NEAR_MISSES))
            title = None if hidden else f"leak-{n}"
        windows.append(Window(1000 + n, owner, title))
    title = draw(st.sampled_from([None, "tab", "Goals", "leak"]))
    return app, windows, title


def matches(app: str, owner: str) -> bool:
    return owner.casefold() == app.casefold() or owner.casefold().startswith(f"{app.casefold()} ")


@settings(
    max_examples=60, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(screen=screens())
def test_no_output_names_another_apps_window(
    tmp_path_factory: pytest.TempPathFactory, stubs: Path, screen: tuple
) -> None:
    app, windows, title = screen
    args = ["--app", app] + (["--title", title] if title else [])
    result = run(tmp_path_factory.mktemp("case"), stubs, windows, *args)
    assert result.code in (0, 1), result.output
    assert "Traceback" not in result.stderr
    for window in windows:
        if not matches(app, window.owner):
            if window.owner.startswith("Otherapp"):
                assert window.owner not in result.output
            if window.title:
                assert window.title not in result.output


@settings(
    max_examples=60, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(screen=screens())
def test_a_captured_window_always_belongs_to_the_app(
    tmp_path_factory: pytest.TempPathFactory, stubs: Path, screen: tuple
) -> None:
    app, windows, title = screen
    args = ["--app", app] + (["--title", title] if title else [])
    result = run(tmp_path_factory.mktemp("case"), stubs, windows, *args)
    assert result.code in (0, 1), result.output
    assert "Traceback" not in result.stderr
    by_id = {f"-l{w.id}": w for w in windows}
    for capture in result.captures:
        assert matches(app, by_id[capture[2]].owner)
        assert capture[:2] == ["-o", "-x"]
