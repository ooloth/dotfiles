#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic==2.14.1"]
# ///
"""Restart a throwaway Rex server and check that tools/rex/saver.py brings its sessions back.

Run by hand when verifying a change to the saver: uv run tools/rex/tests/live_restore.py

CI cannot run it, because Rex is not installed there, so it is not named test_*.py and
scripts/checks/tests.bash does not run it. It never touches your own Rex server: it starts its
own on a private socket, with a config that starts the saver against that server and a scratch
state directory, and stops it at the end. Each check prints PASS or FAIL, and the script exits 1 if
any failed.
"""

from __future__ import annotations

import json
import os
import plistlib
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

REX_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REX_DIR))
import saver  # noqa: E402

SAVER = REX_DIR / "saver.py"
UV = Path.home() / ".local/bin/uv"
REX_ID = re.compile(r"(block|window|session|split):[0-9a-f]{8}-[0-9a-f]{4}-")
failures: list[str] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"{'PASS' if ok else 'FAIL'}  {name}{f'  ({detail})' if detail and not ok else ''}")
    if not ok:
        failures.append(name)


def wait_for(what: str, condition: Any, timeout: float = 20.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if condition():
            return True
        time.sleep(0.25)
    print(f"      timed out after {timeout:.0f}s waiting for {what}")
    return False


class Server:
    def __init__(self, scratch: Path, rex: Path) -> None:
        self.socket = f"unix:///tmp/rexlive{os.getpid()}.sock"
        self.rex = rex
        self.scratch = scratch
        self.state = scratch / "state"
        self.config = scratch / "init.lua"
        self.preferences = scratch / "app.plist"
        # The saver starts only while this file exists, so a test can make a session first, as the
        # app does when it finds a new server empty.
        self.gate = scratch / "start-saver"
        self.gate.touch()
        self.config.write_text(
            f"local gate = io.open({json.dumps(str(self.gate))})\n"
            "if gate then\n"
            "gate:close()\n"
            "rex.exec.start({"
            + ", ".join(
                json.dumps(str(a))
                for a in [
                    UV,
                    "run",
                    "--offline",
                    "--quiet",
                    "--script",
                    SAVER,
                    "run",
                    "--state-dir",
                    self.state,
                    "--server",
                    self.socket,
                    "--rex",
                    rex,
                    "--app-preferences",
                    self.preferences,
                ]
            )
            + "}, { detach = true, stdout = false, stderr = false })\n"
            "end\n"
        )
        self.session = f"rexlive{os.getpid()}"

    def start(self) -> None:
        command = (
            f"{json.dumps(str(self.rex))} server run --listen {self.socket} "
            f"--state-dir {self.scratch / 'server'} --config {self.config}"
        )
        subprocess.run(["tmux", "new-session", "-d", "-s", self.session, command], check=True)
        wait_for("the server", lambda: self.cli("server", "status").returncode == 0)

    def stop(self) -> None:
        subprocess.run(["tmux", "kill-session", "-t", self.session], capture_output=True)
        wait_for("the server to stop", lambda: self.cli("server", "status").returncode != 0)
        Path(self.socket.removeprefix("unix://")).unlink(missing_ok=True)

    def cli(self, *args: str, stdin: str | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.rex), "--autostart=false", "-S", self.socket, *args],
            input=stdin,
            capture_output=True,
            text=True,
        )

    def call(self, method: str, args: dict[str, Any] | None = None) -> Any:
        done = self.cli("api", "call", method, json.dumps(args or {}))
        if done.returncode != 0:
            raise RuntimeError(f"{method}: {done.stderr}")
        return json.loads(done.stdout)

    def sessions(self) -> list[dict[str, Any]]:
        return [
            self.call("session.view", {"session_id": s["session_id"]})
            for s in self.call("session.list")["sessions"]
        ]

    def savers(self) -> int:
        # `uv run` starts Python as a child, so each saver is one uv process and one Python one.
        # Count the Python processes.
        pattern = f"[Pp]ython[^ ]* [^ ]*saver\\.py run --state-dir {self.state}"
        done = subprocess.run(["pgrep", "-f", "--", pattern], capture_output=True)
        return len(done.stdout.split())


def focus_the_app_on(server: Server, session_id: str) -> None:
    """Write the preference the Rex app keeps for the session it shows."""
    value = json.dumps({"sessionID": session_id}).encode()
    server.preferences.write_bytes(plistlib.dumps({"Workspace.lastFocusedSession": value}))


def layout_of(view: dict[str, Any], cwds: dict[str, str]) -> saver.SavedSession:
    result = saver.parse_session(view, cwds)
    assert isinstance(result, saver.Ok), result
    return result.value


def resolved(layout: saver.Layout) -> saver.Layout:
    """`layout` with each directory's symlinks resolved, since macOS's /tmp is /private/tmp."""
    match layout:
        case saver.SavedPane(label=label, cwd=cwd):
            real = saver.AbsolutePath(os.path.realpath(cwd)) if cwd else None
            return saver.SavedPane(label, real)
        case saver.SavedSplit(direction=d, ratio=r, before=b, after=a):
            return saver.SavedSplit(d, r, resolved(b), resolved(a))


def main() -> int:
    rex = saver.find_rex(None)
    with tempfile.TemporaryDirectory() as tmp:
        server = Server(Path(tmp), rex)
        server.start()
        try:
            run(server)
        finally:
            server.stop()
    print(f"\n{len(failures)} check(s) failed" if failures else "\nall checks passed")
    return 1 if failures else 0


def run(server: Server) -> None:
    status = server.state / "status.json"
    check("the saver starts with the server", wait_for("status.json", status.exists))

    # Two sessions: one with a labelled split tab and a second tab, focused on the first tab.
    shell = "com.superlogical.terminal.shell"
    work = server.call(
        "session.create",
        {
            "label": "work",
            "initial_windows": [
                {
                    "window_label": "edit",
                    "layout": {
                        "split": {
                            "direction": "horizontal",
                            "ratio": 0.3,
                            "before": {
                                "block": {
                                    "flavor": shell,
                                    "label": "left",
                                    "options": {"cwd": "/tmp"},
                                }
                            },
                            "after": {
                                "split": {
                                    "direction": "vertical",
                                    "ratio": 0.7,
                                    "before": {
                                        "block": {"flavor": shell, "options": {"cwd": "/usr"}}
                                    },
                                    "after": {
                                        "block": {"flavor": shell, "options": {"cwd": "/etc"}}
                                    },
                                }
                            },
                        }
                    },
                },
                {"layout": {"block": {"flavor": shell, "options": {"cwd": "/var"}}}},
            ],
        },
    )
    first_window = work["initial_windows"][0]["window_id"]
    focused = server.cli(
        "do",
        "-e",
        f'rex.call("session.attach", {{ session_id = "{work["session_id"]}" }}) '
        f'rex.call("session.focus_window", {{ session_id = "{work["session_id"]}", '
        f'window_id = "{first_window}" }})',
    )
    check("the first tab is focused before the restart", focused.returncode == 0, focused.stderr)
    server.call(
        "session.create",
        {"label": "notes", "initial_windows": [{"layout": {"block": {"flavor": shell}}}]},
    )

    latest = server.state / "latest.json"

    def saved_labels() -> list[str]:
        if not latest.exists():
            return []
        loaded = saver.load_snapshot(latest.read_text())
        return [s.label for s in loaded.value.sessions] if isinstance(loaded, saver.Ok) else []

    check(
        "both sessions are saved within a few seconds",
        wait_for("latest.json to list both sessions", lambda: saved_labels() == ["work", "notes"]),
        str(saved_labels()),
    )
    notes_id = next(v["session_id"] for v in server.sessions() if v["label"] == "notes")
    focus_the_app_on(server, notes_id)

    def saved_focus() -> int | None:
        loaded = saver.load_snapshot(latest.read_text())
        return loaded.value.focused_index if isinstance(loaded, saver.Ok) else None

    check(
        "the session the app shows is saved by the next poll",
        wait_for("latest.json to save the focus", lambda: saved_focus() == 1, 40),
        str(saved_focus()),
    )
    time.sleep(2)
    before = {v["label"]: v for v in server.sessions()}
    loaded = saver.load_snapshot(latest.read_text())
    assert isinstance(loaded, saver.Ok)
    saved: dict[str, saver.SavedSession] = {s.label: s for s in loaded.value.sessions}
    check(
        "the saved layout matches the live one, with directories",
        resolved(saved["work"].windows[0].layout)
        == saver.SavedSplit(
            "horizontal",
            saver.Ratio(0.3),
            saver.SavedPane(saver.PaneLabel("left"), saver.AbsolutePath("/private/tmp")),
            saver.SavedSplit(
                "vertical",
                saver.Ratio(0.7),
                saver.SavedPane(saver.PaneLabel("shell"), saver.AbsolutePath("/usr")),
                saver.SavedPane(saver.PaneLabel("shell"), saver.AbsolutePath("/private/etc")),
            ),
        )
        and saved["work"].active_index == 0,
        repr(saved["work"]),
    )

    for _ in range(2):
        server.cli("config", "check")
    server.cli("config", "reload")
    time.sleep(12)  # a losing copy waits up to 10 seconds for the lock before it exits
    check(
        "one saver runs after a config check and reload", server.savers() == 1, str(server.savers())
    )

    files = [p for p in server.state.rglob("*.json")]
    text = "\n".join(p.read_text() for p in files)
    check("no saved file holds a Rex ID", REX_ID.search(text) is None)
    check("the state directory is private", (server.state.stat().st_mode & 0o077) == 0)

    # Restart the server: everything in memory is gone, and the saver should rebuild it. The app
    # makes an empty session as soon as it finds the new server empty, before the saver starts.
    server.stop()
    server.gate.unlink()
    server.start()
    empty = server.call(
        "session.create",
        {"label": "polished-hollow", "initial_windows": [{"layout": {"block": {"flavor": shell}}}]},
    )
    empty_block = empty["initial_windows"][0]["block_ids"][0]

    def shell_started() -> bool:
        process = server.call(
            "com.superlogical.terminal.process",
            {"session_id": empty["session_id"], "block_id": empty_block},
        )
        return bool(process.get("foreground"))

    wait_for("the empty session's shell", shell_started)
    server.gate.touch()
    server.cli("config", "reload")

    def restored() -> bool:
        try:
            labels = sorted(v["label"] for v in server.sessions())
        except RuntimeError:
            return False
        return labels == ["notes", "work"]

    check("both sessions come back after the restart", wait_for("the restore", restored, 40))
    after = {v["label"]: v for v in server.sessions()}
    if "notes" in after:
        focus_the_app_on(server, after["notes"]["session_id"])
        check(
            "the focused session is built into the app's empty session",
            after["notes"]["session_id"] == empty["session_id"],
            f"{after['notes']['session_id']} != {empty['session_id']}",
        )
        check(
            "the app's original tab is gone, leaving the saved one",
            [w["window_id"] for w in after["notes"]["windows"]]
            != [empty["initial_windows"][0]["window_id"]]
            and len(after["notes"]["windows"]) == 1,
            str(after["notes"]["windows"]),
        )
        check(
            "the sessions are in their saved order",
            [v["label"] for v in server.sessions()] == ["work", "notes"],
            str([v["label"] for v in server.sessions()]),
        )
    if "work" in after:
        check(
            "the restored session has the same tabs, splits, labels and active tab",
            layout_of(after["work"], {}) == layout_of(before["work"], {}),
            f"{layout_of(after['work'], {})!r}",
        )
        owners = [
            b.get("owner")
            for w in after["work"]["windows"]
            for layer in w["layers"]
            for b in layer["blocks"]
        ]
        check("restored panes are held by no client", owners == [None] * len(owners), str(owners))
        blocks = [
            b["block_id"]
            for w in after["work"]["windows"]
            for layer in w["layers"]
            for b in layer["blocks"]
        ]
        cwds = {
            block: server.call(
                "com.superlogical.terminal.process",
                {"session_id": after["work"]["session_id"], "block_id": block},
            )["foreground"]["cwd"]
            for block in blocks
        }
        check(
            "restored panes open in their saved directories",
            sorted(cwds.values()) == ["/private/etc", "/private/tmp", "/private/var", "/usr"],
            str(sorted(cwds.values())),
        )

    server.cli("config", "reload")
    time.sleep(12)
    check(
        "a reload after the restore creates no duplicates",
        sorted(v["label"] for v in server.sessions()) == ["notes", "work"],
    )
    check("one saver runs after the restart", server.savers() == 1, str(server.savers()))
    log = (server.state / "saver.log").read_text()
    check("the log records the restore", "restoring 2 session(s)" in log, log[-500:])
    check("no warning was raised", not (server.state / "warning").exists())


if __name__ == "__main__":
    sys.exit(main())
