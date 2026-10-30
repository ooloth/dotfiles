#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Print every package the given test files declare in their inline script headers, one per line.

Run with: uv run scripts/checks/test-dependencies.py <test file>...
Its tests: uv run scripts/checks/tests/test_test_dependencies.py

scripts/checks/tests.bash runs every test in one pytest process, which ignores each file's header,
so it installs what this prints instead. Each file keeps its header, so it still runs on its own with
`uv run <file>`, and the header stays the only place its dependencies are written. Decision 001's
addendum records why, until the shared pyproject.toml of decision 008 replaces this.

The header is read with the regex the inline script metadata spec gives, then parsed as TOML, so a
list spread over several lines is read whole. A header that does not parse fails, naming the file.
"""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path

# From https://packaging.python.org/en/latest/specifications/inline-script-metadata/
BLOCK = re.compile(r"(?m)^# /// (?P<type>[a-zA-Z0-9-]+)$\s(?P<content>(^#(| .*)$\s)+)^# ///$")


def dependencies_of(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    block = next((m for m in BLOCK.finditer(text) if m.group("type") == "script"), None)
    if block is None:
        return []
    toml = "".join(
        line[2:] if line.startswith("# ") else line[1:]
        for line in block.group("content").splitlines(keepends=True)
    )
    try:
        declared = tomllib.loads(toml).get("dependencies", [])
    except tomllib.TOMLDecodeError as error:
        raise SystemExit(f"{path}: its script header is not valid TOML ({error}).") from None
    if not isinstance(declared, list) or not all(isinstance(d, str) for d in declared):
        raise SystemExit(f"{path}: `dependencies` in its script header is not a list of strings.")
    return declared


def main() -> int:
    paths = [Path(arg) for arg in sys.argv[1:]]
    if not paths:
        raise SystemExit("No test files given, so there are no dependencies to read.")
    for dependency in sorted({d for path in paths for d in dependencies_of(path)}):
        print(dependency)
    return 0


if __name__ == "__main__":
    sys.exit(main())
