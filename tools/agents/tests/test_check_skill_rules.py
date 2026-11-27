#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Tests for tools/agents/check-skill-rules.py.

Run with: uv run tools/agents/tests/test_check_skill_rules.py

Each test writes skills and a settings file into a throwaway directory and runs the checker on them
as a subprocess, so the checker stays a single file that nothing imports. The last test runs it with
no arguments on the real repository.
"""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

CHECKER = Path(__file__).resolve().parent.parent / "check-skill-rules.py"
FRONTMATTER = "---\nname: {name}\ndescription: An example skill.\n---\n\n"
TILDE_RULE = "Bash(uv run ~/.claude/skills/example/scripts/run.py *)"
COMMAND = "uv run ~/.claude/skills/example/scripts/run.py --flag\n"
SCRIPT = {"example/scripts/run.py": "print()\n"}


@dataclass(frozen=True)
class Run:
    status: int
    stdout: str


def skill(body: str, name: str = "example") -> dict[str, str]:
    return {f"{name}/SKILL.md": FRONTMATTER.format(name=name) + body}


def run_checker(
    files: dict[str, str],
    *rules: str,
    settings_text: str | None = None,
    settings: bool = True,
    gitignore: str = "",
) -> Run:
    """Write `files` into a skills directory in a fresh git repo, and `rules` as a settings file's
    allow list. `gitignore` becomes the repo's .gitignore, since the checker reads only the skill
    files git does not ignore."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        skills = root / "skills"
        skills.mkdir()
        subprocess.run(["git", "init", "--quiet", str(root)], check=True)
        (root / ".gitignore").write_text(gitignore, encoding="utf-8")
        for name, content in files.items():
            path = skills / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        settings_file = root / "settings.json"
        if settings:
            text = settings_text or json.dumps({"permissions": {"allow": list(rules)}})
            settings_file.write_text(text, encoding="utf-8")
        result = subprocess.run(
            ["uv", "run", "--quiet", "--script", str(CHECKER), str(skills), str(settings_file)],
            capture_output=True,
            text=True,
        )
        return Run(result.returncode, result.stdout + result.stderr)


class AllowRules(unittest.TestCase):
    """A Bash allow rule for a skill script is in the one shape whose text an agent writes."""

    def test_a_tilde_rule_whose_skill_writes_the_command_passes(self) -> None:
        run = run_checker(skill(COMMAND) | SCRIPT, TILDE_RULE)
        self.assertEqual(run.status, 0, run.stdout)
        self.assertIn("Checked 1 allow rules for skill scripts", run.stdout)

    def test_an_absolute_home_path_rule_fails_and_asks_for_tilde(self) -> None:
        rule = "Bash(uv run /Users/alice/.claude/skills/example/scripts/run.py *)"
        run = run_checker(skill(COMMAND) | SCRIPT, rule)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn(rule, run.stdout)
        self.assertIn("`/Users/alice/.claude/skills/`, not `~/.claude/skills/`", run.stdout)

    def test_a_bash_rule_naming_a_skill_script_in_another_shape_fails(self) -> None:
        rule = "Bash(python ~/.claude/skills/example/scripts/run.py *)"
        run = run_checker(skill(COMMAND) | SCRIPT, rule)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn(rule, run.stdout)
        self.assertIn("not in the shape", run.stdout)

    def test_a_rule_naming_the_script_by_its_repo_path_fails(self) -> None:
        rule = "Bash(uv run ~/Repos/example/tools/agents/config/skills/example/scripts/run.py *)"
        run = run_checker(skill(COMMAND) | SCRIPT, rule)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn(rule, run.stdout)

    def test_a_rule_for_a_script_that_does_not_exist_fails(self) -> None:
        run = run_checker(skill(COMMAND), TILDE_RULE)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("no such script: example/scripts/run.py", run.stdout)

    def test_a_rule_for_a_skill_that_does_not_exist_fails(self) -> None:
        rule = "Bash(uv run ~/.claude/skills/missing/scripts/run.py *)"
        run = run_checker(skill("Fine.\n"), rule)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("no such skill: missing/SKILL.md", run.stdout)

    def test_a_read_rule_naming_a_skills_path_is_ignored(self) -> None:
        run = run_checker(skill(COMMAND) | SCRIPT, TILDE_RULE, "Read(~/.claude/skills/**)")
        self.assertEqual(run.status, 0, run.stdout)
        self.assertIn("Checked 1 allow rules for skill scripts", run.stdout)

    def test_rules_that_name_no_skill_script_are_ignored(self) -> None:
        run = run_checker(skill(COMMAND) | SCRIPT, TILDE_RULE, "Bash(acli jira workitem view *)")
        self.assertEqual(run.status, 0, run.stdout)
        self.assertIn("Checked 1 allow rules for skill scripts", run.stdout)

    def test_settings_with_no_rule_for_a_skill_script_fail_as_nothing_to_check(self) -> None:
        run = run_checker(skill("Fine.\n"), "Bash(acli jira workitem view *)")
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("Checked 0 allow rules for skill scripts", run.stdout)
        self.assertIn("nothing to check", run.stdout)


class CommandText(unittest.TestCase):
    """Every skill that writes a ruled script's command writes the rule's exact text."""

    def test_a_skill_that_writes_only_the_base_dir_placeholder_fails(self) -> None:
        run = run_checker(
            skill("uv run <skill-base-dir>/scripts/run.py --flag\n") | SCRIPT, TILDE_RULE
        )
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("never writes `uv run ~/.claude/skills/example/scripts/run.py`", run.stdout)
        self.assertIn("<skill-base-dir>/scripts/run.py", run.stdout)

    def test_a_skill_that_writes_both_forms_fails_on_the_other_one(self) -> None:
        body = COMMAND + "Or: uv run <skill-base-dir>/scripts/run.py --flag\n"
        run = run_checker(skill(body) | SCRIPT, TILDE_RULE)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("example/SKILL.md:7", run.stdout)
        self.assertIn("<skill-base-dir>/scripts/run.py", run.stdout)

    def test_another_skill_that_writes_the_script_another_way_fails(self) -> None:
        other = skill("uv run <skill-base-dir>/../example/scripts/run.py\n", name="other")
        run = run_checker(skill(COMMAND) | SCRIPT | other, TILDE_RULE)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("other/SKILL.md:6", run.stdout)

    def test_another_skill_that_writes_the_rules_command_passes(self) -> None:
        other = skill("Run " + COMMAND, name="other")
        run = run_checker(skill(COMMAND) | SCRIPT | other, TILDE_RULE)
        self.assertEqual(run.status, 0, run.stdout)

    def test_a_skill_file_git_ignores_is_not_read(self) -> None:
        synced = {"synced/third/SKILL.md": "uv run <skill-base-dir>/../example/scripts/run.py\n"}
        run = run_checker(
            skill(COMMAND) | SCRIPT | synced, TILDE_RULE, gitignore="skills/synced/\n"
        )
        self.assertEqual(run.status, 0, run.stdout)

    def test_a_script_of_the_same_name_in_another_skill_is_not_this_one(self) -> None:
        other = skill("uv run <skill-base-dir>/scripts/run.py\n", name="other")
        run = run_checker(skill(COMMAND) | SCRIPT | other, TILDE_RULE)
        self.assertEqual(run.status, 0, run.stdout)


class SettingsFiles(unittest.TestCase):
    """A settings file the checker is told to read must be there and readable."""

    def test_settings_that_are_not_json_fail_as_uncheckable(self) -> None:
        run = run_checker(skill("Fine.\n"), settings_text="{ not json")
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("settings.json", run.stdout)
        self.assertIn("can't be checked", run.stdout)

    def test_a_settings_file_that_does_not_exist_fails(self) -> None:
        run = run_checker(skill("Fine.\n"), settings=False)
        self.assertEqual(run.status, 1, run.stdout)
        self.assertIn("settings.json", run.stdout)
        self.assertIn("can't be checked", run.stdout)

    def test_with_no_arguments_the_real_repo_passes(self) -> None:
        result = subprocess.run(
            ["uv", "run", "--quiet", "--script", str(CHECKER)], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r"Checked [1-9]\d* allow rules for skill scripts")


if __name__ == "__main__":
    unittest.main()
