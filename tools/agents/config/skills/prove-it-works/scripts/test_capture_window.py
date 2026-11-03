"""Black-box tests for capture_window.py.

The script runs as a subprocess, never imported, so it stays a single file. A fake `osascript` on
PATH prints a window list from a fixture file, and a fake `screencapture` records its arguments and
writes an image (or fails, or writes nothing), so no test reads the real screen. That keeps every
property checkable in CI, where there is no screen to capture.

The timeout test is the exception: it loads the script in-process and shortens its timeout, because
a subprocess would wait the full 30 seconds.

Run:
  uv run --with pytest --with pytest-xdist --with hypothesis --with pydantic pytest \
    tools/agents/config/skills/prove-it-works/scripts/test_capture_window.py
"""

import importlib.util
import json
import os
import subprocess
import sys
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType

import pytest
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st

SCRIPT = Path(__file__).with_name("capture_window.py")

# The fakes name this interpreter in their shebang, so they run with PATH holding only the stubs.
FAKE_OSASCRIPT = f"""#!{sys.executable}
import os, sys, time
if os.environ.get("FAKE_OSASCRIPT_HANG"):
    time.sleep(60)
if os.environ.get("FAKE_OSASCRIPT_FAIL"):
    print("execution error: not allowed", file=sys.stderr)
    sys.exit(1)
sys.stdout.write(open(os.environ["FAKE_WINDOWS"]).read())
"""

FAKE_SCREENCAPTURE = f"""#!{sys.executable}
import json, os, sys, time
with open(os.environ["FAKE_LOG"], "a") as log:
    log.write(json.dumps(sys.argv[1:]) + "\\n")
mode = os.environ.get("FAKE_CAPTURE", "ok")
if mode == "hang":
    time.sleep(60)
if mode == "fail":
    print("could not create image from window", file=sys.stderr)
    sys.exit(1)
if mode in ("ok", "race"):
    open(sys.argv[-1], "wb").write(b"\\x89PNG fake image")
if mode == "race":
    open(os.environ["FAKE_RACE_PATH"], "wb").write(b"someone else's file")
if mode == "zero":
    open(sys.argv[-1], "wb").close()
if mode not in ("ok", "race", "zero", "fail", "hang", "empty"):
    sys.exit(f"fake screencapture: unknown FAKE_CAPTURE mode {{mode!r}}")
# "empty" reports success and writes nothing.
"""


@dataclass(frozen=True)
class Window:
    id: int
    owner: str
    title: str | None


def stub_folder(factory: pytest.TempPathFactory, *names: str) -> Iterator[Path]:
    """Write the named fake tools into a folder made read-only so tests can't change them."""
    bodies = {"osascript": FAKE_OSASCRIPT, "screencapture": FAKE_SCREENCAPTURE}
    folder = factory.mktemp("stubs")
    for name in names:
        tool = folder / name
        tool.write_text(bodies[name])
        tool.chmod(0o755)
    folder.chmod(0o555)
    yield folder
    folder.chmod(0o755)


@pytest.fixture(scope="module")
def stubs(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    yield from stub_folder(tmp_path_factory, "osascript", "screencapture")


@pytest.fixture(scope="module")
def without_osascript(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    yield from stub_folder(tmp_path_factory, "screencapture")


@pytest.fixture(scope="module")
def without_screencapture(tmp_path_factory: pytest.TempPathFactory) -> Iterator[Path]:
    yield from stub_folder(tmp_path_factory, "osascript")


@dataclass(frozen=True)
class Run:
    code: int
    stdout: str
    stderr: str
    captures: list[list[str]]

    @property
    def output(self) -> str:
        return self.stdout + self.stderr

    @property
    def captured_ids(self) -> list[str]:
        return [capture[2] for capture in self.captures]


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
            "PATH": str(stubs),
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
    [capture] = result.captures
    assert capture[:3] == ["-o", "-x", "-l727"]
    assert Path(capture[3]).parent.parent == tmp_path / "evidence"


def test_spaces_around_the_app_name_are_ignored(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [REX], "--app", " Rex ")
    assert result.code == 0, result.output
    assert result.captured_ids == ["-l727"]


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


def test_a_title_that_matches_no_window_lists_only_that_apps_titles(
    tmp_path: Path, stubs: Path
) -> None:
    result = run(tmp_path, stubs, [REX, MESSAGES], "--app", "Rex", "--title", "nothing like it")
    assert result.code == 1
    assert result.captures == []
    assert "No on-screen window of Rex" in result.stderr
    assert "nothing like it" in result.stderr
    assert "Agent scaling options - Goals" in result.stderr
    assert "Messages" not in result.output
    assert "A private contact" not in result.output


def test_an_empty_window_list_says_the_app_has_no_window(tmp_path: Path, stubs: Path) -> None:
    result = run(tmp_path, stubs, [], "--app", "Rex")
    assert result.code == 1
    assert result.captures == []
    assert "No on-screen window of Rex" in result.stderr


def test_hidden_titles_report_the_missing_screen_recording_permission(
    tmp_path: Path, stubs: Path
) -> None:
    hidden = [Window(727, "Rex Beta", None), Window(139, "Safari", None)]
    result = run(tmp_path, stubs, hidden, "--app", "Rex")
    assert result.code == 1
    assert result.captures == []
    assert "Screen Recording" in result.stderr


def test_a_hidden_title_on_the_apps_window_reports_screen_recording_even_when_others_show(
    tmp_path: Path, stubs: Path
) -> None:
    terminal = Window(5, "Ghostty", "my shell")
    result = run(tmp_path, stubs, [Window(727, "Rex Beta", None), terminal], "--app", "Rex")
    assert result.code == 1
    assert result.captures == []
    assert "Screen Recording" in result.stderr


def test_a_window_id_picks_an_untitled_window_among_several(tmp_path: Path, stubs: Path) -> None:
    untitled = Window(137, "Safari", "")
    result = run(tmp_path, stubs, [untitled, SAFARI], "--app", "Safari", "--window-id", "137")
    assert result.code == 0, result.output
    assert result.captured_ids == ["-l137"]


def test_a_window_id_of_another_apps_window_is_refused_without_naming_it(
    tmp_path: Path, stubs: Path
) -> None:
    result = run(tmp_path, stubs, [REX, MESSAGES], "--app", "Rex", "--window-id", "620")
    assert result.code == 1
    assert result.captures == []
    assert "Messages" not in result.output
    assert "A private contact" not in result.output


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


def test_a_dangling_symlink_at_the_output_is_refused_and_not_followed(
    tmp_path: Path, stubs: Path
) -> None:
    target = tmp_path / "evidence" / "shot.png"
    target.parent.mkdir(parents=True)
    elsewhere = tmp_path / "elsewhere.png"
    target.symlink_to(elsewhere)
    result = run(tmp_path, stubs, [REX], "--app", "Rex", out=target)
    assert result.code == 1
    assert result.captures == []
    assert not elsewhere.exists()
    assert "already exists" in result.stderr


def test_a_file_that_appears_at_the_output_during_the_capture_is_left_unchanged(
    tmp_path: Path, stubs: Path
) -> None:
    target = tmp_path / "evidence" / "shot.png"
    result = run(
        tmp_path, stubs, [REX], "--app", "Rex", FAKE_CAPTURE="race", FAKE_RACE_PATH=str(target)
    )
    assert result.code == 1
    assert target.read_bytes() == b"someone else's file"
    assert "left unchanged" in result.stderr
    assert sorted(p.name for p in target.parent.iterdir()) == ["shot.png"]


def test_an_output_folder_that_cannot_be_created_exits_with_a_sentence(
    tmp_path: Path, stubs: Path
) -> None:
    blocker = tmp_path / "not-a-folder"
    blocker.write_text("a file")
    result = run(tmp_path, stubs, [REX], "--app", "Rex", out=blocker / "shot.png")
    assert result.code == 1
    assert result.captures == []
    assert "Could not create" in result.stderr
    assert "Traceback" not in result.stderr


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


def test_a_missing_osascript_exits_with_a_sentence_naming_it(
    tmp_path: Path, without_osascript: Path
) -> None:
    result = run(tmp_path, without_osascript, [REX], "--app", "Rex")
    assert result.code == 1
    assert result.captures == []
    assert "osascript was not found" in result.stderr
    assert "Traceback" not in result.stderr


def test_a_missing_screencapture_exits_with_a_sentence_naming_it(
    tmp_path: Path, without_screencapture: Path
) -> None:
    result = run(tmp_path, without_screencapture, [REX], "--app", "Rex")
    assert result.code == 1
    assert "screencapture was not found" in result.stderr
    assert "Traceback" not in result.stderr
    assert sorted((tmp_path / "evidence").iterdir()) == []


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
    assert not (tmp_path / "evidence" / "shot.png").exists()


def test_a_zero_byte_capture_exits_with_a_sentence_and_leaves_no_file(
    tmp_path: Path, stubs: Path
) -> None:
    result = run(tmp_path, stubs, [REX], "--app", "Rex", FAKE_CAPTURE="zero")
    assert result.code == 1
    assert "no image" in result.stderr
    assert sorted((tmp_path / "evidence").iterdir()) == []


# Hung tools, in-process so the timeout can be shortened


def load_script(monkeypatch: pytest.MonkeyPatch) -> ModuleType:
    """Import the script by path. Dataclasses look their module up in sys.modules while it loads."""
    spec = importlib.util.spec_from_file_location("capture_window", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    monkeypatch.setitem(sys.modules, "capture_window", module)
    spec.loader.exec_module(module)
    return module


@pytest.mark.parametrize(
    ("hang", "tool"),
    [({"FAKE_OSASCRIPT_HANG": "1"}, "osascript"), ({"FAKE_CAPTURE": "hang"}, "screencapture")],
)
def test_a_hung_tool_ends_in_a_sentence_once_the_timeout_passes(
    tmp_path: Path, stubs: Path, monkeypatch: pytest.MonkeyPatch, hang: dict[str, str], tool: str
) -> None:
    listing = tmp_path / "windows.json"
    listing.write_text(json.dumps([REX.__dict__]))
    monkeypatch.setenv("PATH", str(stubs))
    monkeypatch.setenv("FAKE_WINDOWS", str(listing))
    monkeypatch.setenv("FAKE_LOG", str(tmp_path / "capture.log"))
    for name, value in hang.items():
        monkeypatch.setenv(name, value)
    script = load_script(monkeypatch)
    monkeypatch.setattr(script, "TOOL_TIMEOUT_SECONDS", 1)
    request = script.parse_arguments(["--app", "Rex", "--out", str(tmp_path / "out" / "shot.png")])
    outcome = script.run(request)
    assert isinstance(outcome, script.Failed)
    assert tool in outcome.message
    assert "did not finish within 1 seconds" in outcome.message
    assert sorted((tmp_path / "out").iterdir()) == []


# The command line


def run_bare(stubs: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        env={**os.environ, "PATH": str(stubs)},
    )


def test_every_argument_problem_is_reported_at_once(stubs: Path) -> None:
    result = run_bare(
        stubs, "--app", " ", "--title", "x", "--window-id", "abc", "--out", "shot.jpg"
    )
    assert result.returncode == 2
    assert "--app needs an app name" in result.stderr
    assert "--window-id must be a positive whole number" in result.stderr
    assert "only one" in result.stderr
    assert ".png" in result.stderr
    assert "Traceback" not in result.stderr


def test_missing_required_arguments_are_reported_together(stubs: Path) -> None:
    result = run_bare(stubs)
    assert result.returncode == 2
    assert "--app is required" in result.stderr
    assert "--out is required" in result.stderr


def test_help_shows_the_whole_docstring(stubs: Path) -> None:
    result = run_bare(stubs, "--help")
    assert result.returncode == 0
    assert "Screen Recording" in result.stdout
    assert "this script cannot judge that" in result.stdout


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
    # candidate (the case that gets captured) common. "some" hides each window's title at random,
    # as macOS does when the terminal's own windows show their titles and other apps' do not.
    hiding = draw(st.sampled_from(["none", "none", "none", "all", "some"]))
    count = draw(st.integers(min_value=0, max_value=4))
    windows: list[Window] = []
    for n in range(count):
        hidden = hiding == "all" or (hiding == "some" and draw(st.booleans()))
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
    if any(matches(app, w.owner) and w.title is None for w in windows):
        assert result.captures == []
        assert "Screen Recording" in result.stderr


@settings(
    max_examples=60, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture]
)
@given(screen=screens(), mode=st.sampled_from(["ok", "fail", "empty", "zero"]))
def test_no_run_leaves_anything_but_the_evidence_in_its_folder(
    tmp_path_factory: pytest.TempPathFactory, stubs: Path, screen: tuple, mode: str
) -> None:
    app, windows, title = screen
    args = ["--app", app] + (["--title", title] if title else [])
    root = tmp_path_factory.mktemp("case")
    result = run(root, stubs, windows, *args, FAKE_CAPTURE=mode)
    assert "Traceback" not in result.stderr
    left = sorted(p.name for p in (root / "evidence").iterdir())
    assert left == (["shot.png"] if result.code == 0 else [])
