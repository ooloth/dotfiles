"""Checks that every standards file scan-system's step 2 names still exists.

The skill tells an agent which standards files to read for each kind of component. A renamed or
deleted standards file would silently drop out of every scan-system run, so this fails instead.

Run:
  uv run --with pytest pytest --import-mode=importlib tools/agents/config/skills/scan-system
"""

import re
from pathlib import Path

import pytest

SKILL = Path(__file__).with_name("SKILL.md")
STANDARDS = Path(__file__).resolve().parents[2] / "standards"


def standards_named_in_step_2(skill_text: str) -> frozenset[str]:
    section = re.search(r"^## 2\..*?(?=^## |\Z)", skill_text, re.DOTALL | re.MULTILINE)
    if section is None:
        raise ValueError("SKILL.md has no '## 2.' section")
    names = frozenset(re.findall(r"`([\w-]+\.md)`", section.group(0)))
    if not names:
        raise ValueError("step 2 names no standards files, so there is nothing to check")
    return names


def missing_standards(names: frozenset[str], standards_dir: Path) -> list[str]:
    return sorted(name for name in names if not (standards_dir / name).is_file())


def test_every_standards_file_step_2_names_exists() -> None:
    names = standards_named_in_step_2(SKILL.read_text())

    assert missing_standards(names, STANDARDS) == [], f"not found in {STANDARDS}"


def test_a_named_file_that_does_not_exist_is_reported() -> None:
    text = (
        "## 2. Check each component\n\n"
        "- **Service:** `reliability.md`, `no-such-standard.md`\n\n"
        "## 3. Rank what fails\n"
    )

    names = standards_named_in_step_2(text)

    assert missing_standards(names, STANDARDS) == ["no-such-standard.md"]


@pytest.mark.parametrize(
    "text",
    [
        pytest.param("## 1. Inventory\n\nNo step 2 here.\n", id="no step 2"),
        pytest.param("## 2. Check each component\n\nNo list.\n\n## 3. Rank\n", id="no names"),
    ],
)
def test_finding_no_names_fails_instead_of_checking_nothing(text: str) -> None:
    with pytest.raises(ValueError):
        standards_named_in_step_2(text)
