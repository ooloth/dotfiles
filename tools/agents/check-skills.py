#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Validate every shared skill: its YAML frontmatter, that it names no fixed temp path, that its
scripts open Claude tabs only with --unattended, and that only create-pr opens a PR.

A skill whose frontmatter is not valid YAML is silently dropped by strict
loaders while lenient ones still load it, so the skill works in one harness
and is absent from another.

A skill that names a fixed path such as /tmp/changes.patch lets two agent
sessions on one machine read and write the same file, so one session can
commit or post the other's content. Every file in a skill is checked, since
its scripts can write to a fixed path as easily as its instructions can.

A script in a skill that opens a Claude Code tab through the Rex launcher starts
a session nobody watches start, which then reads text other people wrote. It
passes --unattended, so cc.bash starts that session in auto mode, where a
classifier checks each action, never in bypass mode. A tab an agent opens from a skill's
instructions, with the user there, is not checked.

create-pr is the one way a PR gets opened: it writes the description, opens the
draft and links it on its Jira, Linear or Monday ticket. An instruction file
that runs gh pr create itself skips all of that. So no file an agent reads as instructions names gh pr create,
except the create-pr skill and use-gh's list of commands that take --body-file.
This check reads the skills and tools/claude/config, which holds CLAUDE.md, the
agents and the routines, and nothing there is exempt.

Git decides which files are skills: tracked files, and untracked ones git does
not ignore, so a new skill is checked before it is committed. A gitignored
file, such as a third-party skill synced into skills/synced/, is not this
repo's to fix and is never checked.

Run it directly, or with uv, optionally passing a skills directory other than
the shared one, then any other instruction directories to check for gh pr create
in place of tools/claude/config:

    ./tools/agents/check-skills.py
    uv run tools/agents/check-skills.py [skills-dir [instruction-dir ...]]
"""

from __future__ import annotations

import re
import subprocess
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


SCRIPT_SUFFIXES = (".py", ".bash", ".sh")
LAUNCHER = "claude-tab.bash"


@dataclass(frozen=True)
class UnreadableFile:
    path: Path


INSTRUCTIONS_DIR = REPO_ROOT / "tools" / "claude" / "config"
OPEN_PR = "gh pr create"
# Paths under the skills directory that may name it: create-pr opens PRs, and use-gh only lists the
# command among those that take --body-file. A path ending in / exempts its whole folder.
OPENS_PR_ALLOWED = ("create-pr/", "use-gh/SKILL.md")


@dataclass(frozen=True)
class PrOpening:
    path: Path
    line: int


def pr_openings(path: Path) -> list[PrOpening] | UnreadableFile:
    """Return each line of this file that names gh pr create, or why it can't be read."""
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return UnreadableFile(path)

    return [
        PrOpening(path, number)
        for number, line in enumerate(text.splitlines(), start=1)
        if OPEN_PR in line
    ]


def may_open_pr(path: Path, skills_dir: Path) -> bool:
    """True when this skill file is one of the places allowed to name gh pr create."""
    relative = path.relative_to(skills_dir).as_posix()
    return any(
        relative.startswith(allowed) if allowed.endswith("/") else relative == allowed
        for allowed in OPENS_PR_ALLOWED
    )


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
    """Every file git tracks or would track under a skills or instruction directory, except
    Python's compiled caches."""
    listed = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=skills_dir,
        capture_output=True,
        text=True,
    )
    if listed.returncode != 0:
        raise SystemExit(
            f"❌ Can't list the files in {skills_dir} with git: {listed.stderr.strip()}"
        )

    # --cached still lists a tracked file deleted from the working tree
    return sorted(
        path
        for name in listed.stdout.split("\0")
        if name and "__pycache__" not in Path(name).parts and (path := skills_dir / name).is_file()
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


def opens_tab_unattended(path: Path) -> bool:
    """False when this skill script names the Rex launcher without passing --unattended."""
    if path.suffix not in SCRIPT_SUFFIXES or path.name.startswith("test_"):
        return True
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return True  # reported by the fixed temp path check
    # A mention in a comment does not pass the flag, so it doesn't count
    code = [line for line in text.splitlines() if not line.lstrip().startswith("#")]
    return LAUNCHER not in text or any("--unattended" in line for line in code)


def shown(path: Path, skills_dir: Path) -> Path:
    """The path as a reader of the output would look for it."""
    return path.relative_to(REPO_ROOT if path.is_relative_to(REPO_ROOT) else skills_dir)


def report_pr_openings(skills_dir: Path, files: list[Path], instruction_dirs: list[Path]) -> bool:
    """Print every place other than create-pr that runs gh pr create, and return whether any did."""
    found: list[tuple[PrOpening, Path]] = []
    unreadable: list[tuple[UnreadableFile, Path]] = []
    empty: list[Path] = []
    checked = 0

    roots = [(skills_dir, files, skills_dir)] + [
        (directory, skill_files(directory) if directory.is_dir() else [], directory.parent)
        for directory in instruction_dirs
    ]
    for root, root_files, base in roots:
        if not root_files:
            empty.append(root)
            continue
        for path in root_files:
            if root == skills_dir and may_open_pr(path, skills_dir):
                continue
            checked += 1
            match pr_openings(path):
                case UnreadableFile() as file:
                    # The fixed temp path check already reports unreadable skill files
                    if root != skills_dir:
                        unreadable.append((file, base))
                case openings:
                    found.extend((opening, base) for opening in openings)

    print(f"\nChecked {checked} instruction files for `{OPEN_PR}` outside create-pr")
    for root in empty:
        print(f"❌ No files found under {root}, so it can't be checked")
    for file, base in unreadable:
        print(f"❌ {shown(file.path, base)}: not UTF-8 text, so it can't be checked")
    for opening, base in found:
        print(
            f"❌ {shown(opening.path, base)}:{opening.line}: runs `{OPEN_PR}`; "
            "open PRs through the create-pr skill instead"
        )
    if found:
        print(
            "\ncreate-pr is the one way a PR gets opened, so it can link the PR on its ticket. "
            "See docs/invariants/skills.md."
        )
    elif not empty and not unreadable:
        print("✅ Only create-pr opens a PR")

    return bool(found or unreadable or empty)


def main() -> int:
    skills_dir = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else SKILLS_DIR
    instruction_dirs = (
        [Path(arg).resolve() for arg in sys.argv[2:]] if len(sys.argv) > 1 else [INSTRUCTIONS_DIR]
    )

    files = skill_files(skills_dir)
    paths = [path for path in files if path.relative_to(skills_dir).parts[1:] == ("SKILL.md",)]
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

    attended = [path for path in files if not opens_tab_unattended(path)]
    print(f"\nChecked {len(files)} skill files for Claude tabs opened without --unattended")
    for path in attended:
        print(f"❌ {shown(path, skills_dir)}: opens a Claude tab without --unattended")
    if attended:
        print(
            "\nA session a script opens starts with nobody watching and reads other people's "
            "text. See docs/invariants/skills.md."
        )
    else:
        print("✅ No skill script opens a Claude tab without --unattended")

    pr_opened = report_pr_openings(skills_dir, files, instruction_dirs)

    return 1 if failures or found or unreadable or attended or pr_opened else 0


if __name__ == "__main__":
    sys.exit(main())
