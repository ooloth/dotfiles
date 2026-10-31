#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Fail when a file this public repo would publish names one of this machine's private values.

The values come from the environment: every PRIVATE_* variable, which tools/bash/private-env.bash
loads from the ignored private.env. Every word of every value is a term, splitting on whitespace
and `=`, so a value added to private.env is covered with no second edit. A term is found in any
letter case, inside a longer name, in a file's contents or its path. The files are the ones git
tracks, and the untracked ones it does not ignore, so a leak is caught before it is committed.

With no terms the check fails, because a check with nothing to look for would always pass. In CI
(CI set) or an Amp orb (AMP_ORB set) there is no private.env, so it skips the search and says so.

It also fails, everywhere, when private.env.example does not document the private keys: a
PRIVATE_* name used outside a tests/ folder must be listed there, and each key there needs a
`# machines:` line naming only air, mini or work. Tests use made-up keys on purpose.

The rule this enforces is docs/invariants/public-repo.md. Run it from the repo root:

    uv run scripts/checks/private_values.py
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

EXAMPLE = "private.env.example"
MACHINES = frozenset({"air", "mini", "work"})
# A key is a whole name, so SSH_PRIVATE_KEY is not one
KEY = re.compile(r"(?<![A-Za-z0-9_])PRIVATE_[A-Z0-9_]+")
ASSIGNMENT = re.compile(r"^(PRIVATE_[A-Z0-9_]+)=")
WORD_SEPARATORS = re.compile(r"[\s=]+")


@dataclass(frozen=True)
class Mention:
    path: str
    line: int | None
    term: str


@dataclass(frozen=True)
class UndocumentedKey:
    key: str
    path: str
    line: int


@dataclass(frozen=True)
class ExampleError:
    line: int
    problem: str


@dataclass(frozen=True)
class NoTerms:
    pass


@dataclass(frozen=True)
class Skipped:
    reason: str


def read_terms(environ: dict[str, str]) -> frozenset[str] | NoTerms | Skipped:
    """Every word of every PRIVATE_* value, lowercased, or why there are none to search for."""
    terms = frozenset(
        word.lower()
        for name, value in environ.items()
        if name.startswith("PRIVATE_")
        for word in WORD_SEPARATORS.split(value)
        if word
    )
    if terms:
        return terms
    if environ.get("CI"):
        return Skipped("CI")
    if environ.get("AMP_ORB"):
        return Skipped("an Amp orb")
    return NoTerms()


def git(*args: str) -> subprocess.CompletedProcess[str]:
    # This repo's git config sets submodule.recurse, and with it `git grep --untracked` exits 128
    return subprocess.run(
        ["git", "-c", "submodule.recurse=false", *args], capture_output=True, text=True
    )


def listed_paths() -> list[str]:
    """Every path git tracks, and every untracked one it does not ignore."""
    listed = git("ls-files", "-z", "--cached", "--others", "--exclude-standard")
    if listed.returncode != 0:
        raise SystemExit(f"❌ Can't list the repo's files with git: {listed.stderr.strip()}")
    return sorted({name for name in listed.stdout.split("\0") if name})


def files_containing(patterns: list[str], *flags: str) -> list[str]:
    """The files that git grep finds any of these fixed-string patterns in."""
    with tempfile.TemporaryDirectory() as directory:
        pattern_file = Path(directory) / "patterns"
        pattern_file.write_text("\n".join(patterns) + "\n", encoding="utf-8")
        found = git("grep", "-F", "-l", "-z", "-a", "--untracked", *flags, "-f", str(pattern_file))
    # 1 means nothing matched; anything else but 0 is git failing, which must not read as a pass
    if found.returncode not in (0, 1):
        raise SystemExit(f"❌ git grep failed: {found.stderr.strip()}")
    return sorted(name for name in found.stdout.split("\0") if name)


def lines_of(path: str) -> list[str]:
    return Path(path).read_bytes().decode("utf-8", errors="replace").splitlines()


def find_mentions(terms: frozenset[str], paths: list[str]) -> list[Mention]:
    """Each path, and each line of each file, that contains a term in any letter case."""
    assert terms, "an empty term set would make every file pass"
    assert all(terms), "an empty term matches every line"

    mentions = [
        Mention(path, None, term)
        for path in paths
        for term in sorted(terms)
        if term in path.lower()
    ]
    for path in files_containing(sorted(terms), "-i"):
        for number, text in enumerate(lines_of(path), start=1):
            lowered = text.lower()
            mentions.extend(
                Mention(path, number, term) for term in sorted(terms) if term in lowered
            )

    assert all(mention.term in terms for mention in mentions)
    return mentions


def read_example(path: Path) -> tuple[frozenset[str], list[ExampleError]]:
    """The keys private.env.example lists, and each line that breaks its format."""
    keys: set[str] = set()
    errors: list[ExampleError] = []
    machines_line: int | None = None
    for number, text in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if text.startswith("# machines:"):
            machines_line = number
            named = text.removeprefix("# machines:").split()
            if not named:
                errors.append(ExampleError(number, "names no machine"))
            errors.extend(
                ExampleError(number, f"unknown machine {name}; use {', '.join(sorted(MACHINES))}")
                for name in named
                if name not in MACHINES
            )
        elif match := ASSIGNMENT.match(text):
            keys.add(match.group(1))
            if machines_line is None:
                errors.append(
                    ExampleError(number, f"{match.group(1)} has no `# machines:` line above it")
                )
            machines_line = None
        elif text.strip() and not text.startswith("#"):
            errors.append(ExampleError(number, "not a comment or a PRIVATE_<NAME>=value line"))
    return frozenset(keys), errors


def find_undocumented(documented: frozenset[str]) -> list[UndocumentedKey]:
    """Each use of a PRIVATE_* name outside a tests/ folder that private.env.example lacks."""
    return [
        UndocumentedKey(key, path, number)
        for path in files_containing(["PRIVATE_"])
        if path != EXAMPLE and "tests" not in Path(path).parts[:-1]
        for number, text in enumerate(lines_of(path), start=1)
        for key in KEY.findall(text)
        if key not in documented
    ]


def main() -> int:
    root = git("rev-parse", "--show-toplevel")
    if root.returncode != 0:
        raise SystemExit(f"❌ Run this inside the repo: {root.stderr.strip()}")
    os.chdir(root.stdout.strip())

    failed = False
    example = Path(EXAMPLE)
    if not example.is_file():
        print(f"❌ No {EXAMPLE}, which lists every private key this repo reads.", file=sys.stderr)
        return 1

    documented, errors = read_example(example)
    for error in errors:
        print(f"❌ {EXAMPLE}:{error.line}: {error.problem}", file=sys.stderr)
    undocumented = find_undocumented(documented)
    for each in undocumented:
        print(f"❌ {each.path}:{each.line}: {each.key} is not in {EXAMPLE}", file=sys.stderr)
    if errors or undocumented:
        failed = True
    else:
        print(f"✅ {EXAMPLE} documents all {len(documented)} private keys")

    match read_terms(dict(os.environ)):
        case Skipped(reason):
            print(f"⏭️  In {reason} there are no private values, so the leak search skipped.")
        case NoTerms():
            print(
                "❌ No PRIVATE_* values are set, so there is nothing to search for. Create "
                "private.env at the repo root from private.env.example, then open a new shell.",
                file=sys.stderr,
            )
            failed = True
        case terms:
            paths = listed_paths()
            mentions = find_mentions(terms, paths)
            for mention in mentions:
                where = "(in the path)" if mention.line is None else ""
                place = mention.path if mention.line is None else f"{mention.path}:{mention.line}"
                print(f"❌ {place}: {mention.term} {where}".rstrip(), file=sys.stderr)
            if mentions:
                print(
                    "\nThis repo is public. Replace each value with a PRIVATE_* variable or a "
                    "made-up name; see docs/invariants/public-repo.md.",
                    file=sys.stderr,
                )
                failed = True
            else:
                print(f"✅ No file names any of {len(terms)} private terms ({len(paths)} files)")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
