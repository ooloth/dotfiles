#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Validate the YAML frontmatter of every shared skill.

A skill whose frontmatter is not valid YAML is silently dropped by strict
loaders while lenient ones still load it, so the skill works in one harness
and is absent from another. Run it directly, or with uv:

    ./tools/agents/check-skills.py
    uv run tools/agents/check-skills.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

SKILLS_DIR = Path(__file__).resolve().parent / "config" / "skills"
REPO_ROOT = Path(__file__).resolve().parents[2]
REQUIRED_KEYS = ("name", "description")


def frontmatter_problem(path: Path) -> str | None:
    """Return why this skill's frontmatter is unusable, or None when it is fine."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return "no YAML frontmatter block"

    parts = text.split("---", 2)
    if len(parts) < 3:
        return "frontmatter block is not closed"

    try:
        parsed = yaml.safe_load(parts[1])
    except yaml.YAMLError as error:
        return f"invalid YAML ({str(error).splitlines()[0]})"

    if not isinstance(parsed, dict):
        return "frontmatter is not a mapping"

    missing = [key for key in REQUIRED_KEYS if key not in parsed]
    if missing:
        return f"frontmatter is missing {', '.join(missing)}"

    return None


def main() -> int:
    paths = sorted(SKILLS_DIR.glob("*/SKILL.md"))
    if not paths:
        print(f"❌ No SKILL.md files found under {SKILLS_DIR}")
        return 1

    failures = [(path, problem) for path in paths if (problem := frontmatter_problem(path))]

    print(f"Checked {len(paths)} skill frontmatter blocks")
    for path, problem in failures:
        print(f"❌ {path.relative_to(REPO_ROOT)}: {problem}")

    if failures:
        print(f"\n{len(failures)} skill(s) have frontmatter a strict loader will reject.")
        return 1

    print("✅ All skill frontmatter parses")
    return 0


if __name__ == "__main__":
    sys.exit(main())
