#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Check that focus_pane_or_tab in tools/rex/config/init.lua and config.nvim's lua/config/rex.lua
move focus through a real Neovim in a real Rex pane.

Run by hand after changing either side, once `rex config reload` has loaded init.lua:
uv run tools/rex/tests/live_nvim.py

CI cannot run it, because Rex and config.nvim are not installed there, so it is not named
test_*.py. It opens a throwaway session on your own Rex server, with Neovim (NVIM_APPNAME=nvim-ide,
which loads ~/Repos/ooloth/config.nvim) split into two windows on a scratch file in the left pane
and a shell in the right one, and closes the session at the end. The action runs through
`rex do`, so it moves between panes but never crosses a tab, and pressing the keys in the app is
still the check for that. Each check prints PASS or FAIL, and the script exits 1 if any failed.
"""

from __future__ import annotations

import json
import os
import statistics
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

NVIM = "/opt/homebrew/bin/nvim"
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


def rex(*args: str) -> str:
    return subprocess.run(["rex", *args], capture_output=True, text=True, check=True).stdout


def lua(session: str, script: str) -> Any:
    return json.loads(rex("do", "-s", session, "-e", script))


def focused_block(session: str) -> str:
    view = json.loads(rex("session", "inspect", session, "--json"))
    active = next(w for w in view["windows"] if w["window_id"] == view["active_window_id"])
    return active["focused_block_id"]


def nvim_expr(socket: Path, expression: str) -> str:
    result = subprocess.run(
        [NVIM, "--clean", "--server", str(socket), "--remote-expr", expression],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def focus(session: str, direction: str) -> str:
    return rex("do", "-s", session, "focus_pane_or_tab", f"direction={direction}").strip()


def main() -> int:
    scratch = Path(tempfile.mkdtemp())
    (scratch / "scratch.txt").write_text("scratch\n")
    session = json.loads(rex("new", "rex-live-nvim", "--json", "-c", str(scratch)))["session_id"]
    try:
        nvim_block = lua(session, "return rex.session.view{}.windows[1].focused_block_id")
        shell = (
            f'{{ flavor = "com.superlogical.terminal.shell", options = {{ cwd = "{scratch}" }} }}'
        )
        shell_block = lua(
            session,
            f'return rex.session.new_split{{ block_id = "{nvim_block}", direction = "horizontal", '
            f'side = "after", layout = rex.layout.block{shell} }}.block_ids[1]',
        )
        lua(session, f'return rex.session.focus_block{{ block_id = "{nvim_block}" }}.revision')

        # -n: no swap file; the scratch file keeps the editor from restoring a session
        command = "NVIM_APPNAME=nvim-ide nvim -n -c vsplit scratch.txt\r"
        lua(
            session,
            f'return rex.block.call("com.superlogical.terminal", "write", '
            f'{{ block_id = "{nvim_block}", data = {json.dumps(command)} }}).bytes_written',
        )
        socket = (
            Path.home() / ".local/state/rex/nvim" / (nvim_block.removeprefix("block:") + ".sock")
        )
        check("nvim opens the socket named after its pane", wait_for(str(socket), socket.exists))
        if not socket.exists():
            return 1
        time.sleep(1)
        # The config may open the split on either side, so start from the left window explicitly
        nvim_expr(socket, "execute('1wincmd w')")
        check("nvim has two windows", nvim_expr(socket, "winnr('$')") == "2")

        answer = focus(session, "right")
        check(
            "right from nvim's left window moves to its right window",
            nvim_expr(socket, "winnr()") == "2" and focused_block(session) == nvim_block,
            answer,
        )

        answer = focus(session, "right")
        check(
            "right at nvim's edge moves to the shell pane",
            focused_block(session) == shell_block,
            answer,
        )

        nvim_expr(socket, "execute('1wincmd w')")
        answer = focus(session, "left")
        check(
            "left from the shell lands in nvim's right window, the side entered from",
            focused_block(session) == nvim_block and nvim_expr(socket, "winnr()") == "2",
            answer,
        )

        timings = []
        for _ in range(15):
            start = time.perf_counter()
            nvim_expr(socket, "v:lua.require'config.rex'.keeps_key(nvim_get_mode())")
            timings.append((time.perf_counter() - start) * 1000)
        median = statistics.median(timings)
        check(f"a round trip to nvim takes {median:.1f} ms at the median, under 20 ms", median < 20)
    finally:
        rex("session", "kill", session)
        socket_dir = Path.home() / ".local/state/rex/nvim"
        print(
            f"      closed {session}; sockets left in {socket_dir}: {len(list(socket_dir.glob('*.sock')))}"
        )

    print(f"{len(failures)} failed" if failures else "all passed")
    return 1 if failures else 0


if __name__ == "__main__":
    os.environ.pop("NVIM", None)
    sys.exit(main())
