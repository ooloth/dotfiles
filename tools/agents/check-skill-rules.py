#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Check that every allow rule for a skill script matches the command every skill writes for it.

Claude Code matches a Bash permission rule against the command's text, not the file it runs. So a
skill script that runs without a prompt has one spelling everywhere: the rule is
`Bash(uv run ~/.claude/skills/<skill>/scripts/<file> *)`, and every skill that runs the script
writes `uv run ~/.claude/skills/<skill>/scripts/<file>`. docs/invariants/skills.md says why.

This check fails:
  - a Bash allow rule naming a skill script (a path with /skills/<skill>/scripts/) that is not in
    that shape, such as one with an absolute home folder or the repo path;
  - a rule whose skill or script does not exist;
  - a rule whose own skill never writes its command;
  - any skill Markdown file that writes the ruled script another way, such as
    `<skill-base-dir>/scripts/<file>` or `<skill-base-dir>/../<skill>/scripts/<file>`;
  - a settings file it was told to read that is missing or not readable;
  - settings that hold no rule for a skill script, since then there is nothing to check.
Rules other than Bash ones, such as Read(...), run nothing and are ignored. Like check-skills.py,
it reads the skill files git does not ignore, so third-party skills in skills/synced/ are skipped.

Usage:
  uv run tools/agents/check-skill-rules.py [<skills-dir> [<settings.json> ...]]
With no arguments it reads tools/agents/config/skills and tools/claude/config/settings.json.
scripts/checks/linting.bash runs it.
"""

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import assert_never

REPO_ROOT = Path(__file__).resolve().parents[2]
SKILLS_DIR = REPO_ROOT / "tools" / "agents" / "config" / "skills"
SETTINGS = REPO_ROOT / "tools" / "claude" / "config" / "settings.json"

SKILL_SCRIPT_RULE = re.compile(
    r"Bash\(uv run (?P<home>\S+?)/\.claude/skills/(?P<skill>[\w.-]+)/scripts/(?P<script>[\w.-]+) \*\)"
)
NAMES_A_SKILL_SCRIPT = re.compile(r"/skills/[\w.-]+/scripts/")


@dataclass(frozen=True)
class SkillScriptRule:
    rule: str
    home: str
    skill: str
    script: str

    def command(self) -> str:
        return f"uv run ~/.claude/skills/{self.skill}/scripts/{self.script}"


@dataclass(frozen=True)
class UnrecognisedRule:
    rule: str


@dataclass(frozen=True)
class UnreadableSettings:
    path: Path
    reason: str


def allow_rules(settings: Path) -> list[SkillScriptRule | UnrecognisedRule] | UnreadableSettings:
    """The Bash allow rules in a settings file that name a skill script, each parsed or refused."""
    try:
        parsed = json.loads(settings.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, ValueError) as error:
        return UnreadableSettings(settings, str(error))
    permissions = parsed.get("permissions", {}) if isinstance(parsed, dict) else None
    allow = permissions.get("allow", []) if isinstance(permissions, dict) else None
    if not isinstance(allow, list) or not all(isinstance(rule, str) for rule in allow):
        return UnreadableSettings(settings, "permissions.allow is not a list of strings")
    rules: list[SkillScriptRule | UnrecognisedRule] = []
    for rule in allow:
        if not rule.startswith("Bash(") or not NAMES_A_SKILL_SCRIPT.search(rule):
            continue
        match = SKILL_SCRIPT_RULE.fullmatch(rule)
        if match is None:
            rules.append(UnrecognisedRule(rule))
        else:
            rules.append(SkillScriptRule(rule, match["home"], match["skill"], match["script"]))
    return rules


def rule_problems(
    rule: SkillScriptRule | UnrecognisedRule, skills_dir: Path, documents: list[Path]
) -> list[str]:
    match rule:
        case UnrecognisedRule():
            return [
                "names a skill script but is not in the shape "
                "`Bash(uv run ~/.claude/skills/<skill>/scripts/<file> *)`, so an agent following "
                "its skill never writes the text it matches"
            ]
        case SkillScriptRule(home=home) if home != "~":
            return [f"names the skills folder as `{home}/.claude/skills/`, not `~/.claude/skills/`"]
        case SkillScriptRule(skill=name, script=script):
            skill_md = skills_dir / name / "SKILL.md"
            if not skill_md.is_file():
                return [f"no such skill: {name}/SKILL.md"]
            if not (skills_dir / name / "scripts" / script).is_file():
                return [f"no such script: {name}/scripts/{script}"]
            found = other_spellings(rule, skills_dir, documents)
            if rule.command() not in skill_md.read_text(encoding="utf-8"):
                found.insert(
                    0,
                    f"{name}/SKILL.md never writes `{rule.command()}`, so an agent types another "
                    "command and gets a permission prompt",
                )
            return found
        case _:
            assert_never(rule)


def other_spellings(rule: SkillScriptRule, skills_dir: Path, documents: list[Path]) -> list[str]:
    """Each place a skill writes this rule's script as anything but the rule's command."""
    token = re.compile(r"[^\s`'\"(]*/scripts/" + re.escape(rule.script) + r"(?![\w.-])")
    exact = f"~/.claude/skills/{rule.skill}/scripts/{rule.script}"
    own_dir = skills_dir / rule.skill
    found: list[str] = []
    for document in documents:
        owned = document.is_relative_to(own_dir)
        for number, line in enumerate(document.read_text(encoding="utf-8").splitlines(), start=1):
            for match in token.finditer(line):
                written = match.group(0)
                names_it = f"/{rule.skill}/scripts/" in written or (
                    owned and written.startswith("<skill-base-dir>/scripts/")
                )
                if not names_it:
                    continue
                if written == exact and line[: match.start()].endswith("uv run "):
                    continue
                found.append(
                    f"{document.relative_to(skills_dir)}:{number} writes `{written}`; write "
                    f"`{rule.command()}`, the text the rule matches"
                )
    return found


def skill_documents(skills_dir: Path) -> list[Path]:
    """Every Markdown file in the skills that git tracks or would track, so ignored ones are skipped."""
    listed = subprocess.run(
        [
            "git",
            "-C",
            str(skills_dir),
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    names = [name for name in listed.stdout.split("\0") if name.endswith(".md")]
    return sorted(skills_dir / name for name in names if (skills_dir / name).is_file())


def main() -> int:
    skills_dir = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else SKILLS_DIR
    settings_files = (
        [Path(arg).resolve() for arg in sys.argv[2:]] if len(sys.argv) > 2 else [SETTINGS]
    )
    documents = skill_documents(skills_dir)
    problems: list[str] = []
    checked = 0
    for settings in settings_files:
        match allow_rules(settings):
            case UnreadableSettings(path=path, reason=reason):
                problems.append(f"{path}: {reason}, so it can't be checked")
            case list() as rules:
                for rule in rules:
                    checked += 1
                    problems += [
                        f"{rule.rule}: {p}" for p in rule_problems(rule, skills_dir, documents)
                    ]
            case other:
                assert_never(other)

    print(f"Checked {checked} allow rules for skill scripts")
    if checked == 0 and not problems:
        problems.append(
            "no allow rule names a skill script, so there is nothing to check; the settings files "
            "read were " + ", ".join(str(s) for s in settings_files)
        )
    for problem in problems:
        print(f"❌ {problem}")
    if problems:
        print(
            "\nA rule matches the command's text, so a skill script runs without a prompt only "
            "when every skill writes the rule's command. See docs/invariants/skills.md."
        )
        return 1
    print("✅ Every allow rule for a skill script matches the command every skill writes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
