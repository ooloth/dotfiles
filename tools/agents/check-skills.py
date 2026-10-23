#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Validate every shared skill: its YAML frontmatter, and that it names no fixed temp path.

A skill whose frontmatter is not valid YAML is silently dropped by strict
loaders while lenient ones still load it, so the skill works in one harness
and is absent from another.

A skill that names a fixed path such as /tmp/changes.patch lets two agent
sessions on one machine read and write the same file, so one session can
commit or post the other's content. Every file in a skill is checked, since
its scripts can write to a fixed path as easily as its instructions can.

Run it directly, or with uv, optionally passing a skills directory other than
the shared one:

    ./tools/agents/check-skills.py
    uv run tools/agents/check-skills.py [skills-dir]
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml

SKILLS_DIR = Path(__file__).resolve().parent / "config" / "skills"
REPO_ROOT = Path(__file__).resolve().parents[2]
REQUIRED_KEYS = ("name", "description")

# A shared temp directory only counts where it starts a path, so ${TMPDIR:-/tmp}/x and ./build/tmp/x
# don't match, and a bare `/tmp` in prose names no file
FIXED_TMP_PATH = re.compile(r"(?<![\w.~}-])/(?:private/|var/)?tmp/[\w.-]+")


@dataclass(frozen=True)
class FixedTmpPath:
    path: Path
    line: int
    fixed_path: str


@dataclass(frozen=True)
class UnreadableFile:
    path: Path


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


def skill_files(skills_dir: Path) -> list[Path]:
    """Every file in every skill, except Python's compiled caches."""
    return sorted(
        path
        for path in skills_dir.rglob("*")
        if path.is_file() and "__pycache__" not in path.relative_to(skills_dir).parts
    )


def fixed_tmp_paths(path: Path) -> list[FixedTmpPath] | UnreadableFile:
    """Return each fixed temp path this file names, or why it can't be read."""
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return UnreadableFile(path)

    return [
        FixedTmpPath(path, number, match.group())
        for number, line in enumerate(text.splitlines(), start=1)
        for match in FIXED_TMP_PATH.finditer(line)
    ]


def shown(path: Path, skills_dir: Path) -> Path:
    """The path as a reader of the output would look for it."""
    return path.relative_to(REPO_ROOT if path.is_relative_to(REPO_ROOT) else skills_dir)


def main() -> int:
    skills_dir = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else SKILLS_DIR

    paths = sorted(skills_dir.glob("*/SKILL.md"))
    if not paths:
        print(f"❌ No SKILL.md files found under {skills_dir}")
        return 1

    failures = [(path, problem) for path in paths if (problem := frontmatter_problem(path))]

    print(f"Checked {len(paths)} skill frontmatter blocks")
    for path, problem in failures:
        print(f"❌ {shown(path, skills_dir)}: {problem}")

    if failures:
        print(f"\n{len(failures)} skill(s) have frontmatter a strict loader will reject.")
    else:
        print("✅ All skill frontmatter parses")

    files = skill_files(skills_dir)
    found: list[FixedTmpPath] = []
    unreadable: list[UnreadableFile] = []
    for path in files:
        match fixed_tmp_paths(path):
            case UnreadableFile() as file:
                unreadable.append(file)
            case paths_in_file:
                found.extend(paths_in_file)

    print(f"\nChecked {len(files)} skill files for fixed temp paths")
    for file in unreadable:
        print(f"❌ {shown(file.path, skills_dir)}: not UTF-8 text, so it can't be checked")
    for each in found:
        print(
            f"❌ {shown(each.path, skills_dir)}:{each.line}: names {each.fixed_path}; "
            "use a directory from `mktemp -d` instead"
        )

    if found or unreadable:
        print(
            "\nTwo sessions using one fixed temp path read and write each other's files. "
            "See docs/invariants/skills.md."
        )
    else:
        print("✅ No skill names a fixed temp path")

    return 1 if failures or found or unreadable else 0


if __name__ == "__main__":
    sys.exit(main())
