"""Black-box tests for check_unread.py.

Each test builds a throwaway git repo, commits the files it needs, and runs the script as a
subprocess from inside it, so the script stays a single file and no test touches a real repo.

Run:
  uv run --with pytest pytest tools/agents/config/skills/commit/scripts/test_check_unread.py
"""

import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("check_unread.py")


def make_repo(tmp_path: Path, files: dict[str, str]) -> Path:
    repo = tmp_path / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    for name, text in files.items():
        path = repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "init"],
        cwd=repo,
        check=True,
    )
    return repo


def run(repo: Path, *paths: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-I", str(SCRIPT), *paths],
        cwd=repo,
        capture_output=True,
        text=True,
    )


BASE = {"CLAUDE.md": "# Notes\n", "app/main.py": "print('hi')\n"}


def test_markdown_nothing_reads_exits_0(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, BASE)
    result = run(repo, "CLAUDE.md")
    assert result.returncode == 0, result.stdout + result.stderr


def test_non_markdown_path_exits_1_and_names_it(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, BASE)
    result = run(repo, "CLAUDE.md", "app/main.py")
    assert result.returncode == 1
    assert "app/main.py" in result.stdout


@pytest.mark.parametrize("name", ["README.markdown", "NOTES.MD", "notes.txt"])
def test_other_prose_extensions_are_not_trusted(tmp_path: Path, name: str) -> None:
    repo = make_repo(tmp_path, {**BASE, name: "x\n"})
    assert run(repo, name).returncode == 1


def test_test_that_opens_the_file_by_name_exits_1(tmp_path: Path) -> None:
    repo = make_repo(
        tmp_path,
        {
            **BASE,
            "DEPLOYMENT.md": "# Deploy\n",
            "tests/test_docs.py": 'GUIDE = ROOT / "DEPLOYMENT.md"\n',
        },
    )
    result = run(repo, "DEPLOYMENT.md")
    assert result.returncode == 1
    assert "tests/test_docs.py:1" in result.stdout


def test_file_named_by_its_full_path_exits_1(tmp_path: Path) -> None:
    repo = make_repo(
        tmp_path,
        {**BASE, "docs/guide.md": "x\n", "check.sh": "cat 'docs/guide.md'\n"},
    )
    assert run(repo, "docs/guide.md").returncode == 1


@pytest.mark.parametrize(
    "line",
    [
        "# --frozen, per CLAUDE.md: a plain uv run re-resolves\n",
        '"""Recorded as EMAIL-SERVICE-CYCLE in ``CLAUDE.md``."""\n',
        "// see CLAUDE.md for why\n",
    ],
)
def test_comment_citing_the_file_does_not_count_as_a_read(tmp_path: Path, line: str) -> None:
    repo = make_repo(tmp_path, {**BASE, "app/cite.py": line})
    result = run(repo, "CLAUDE.md")
    assert result.returncode == 0, result.stdout


@pytest.mark.parametrize(
    "line",
    [
        'for p in ROOT.rglob("*.md"):\n',
        "files: '**/*.md'\n",
        'if path.suffix == ".md":\n',
        "if name.endswith('.md'):\n",
        'open(f"{name}.md")\n',
        "files: \\.md$\n",
        'DOC = re.compile(r"[^/]+\\.mdx?")\n',
    ],
)
def test_reader_of_every_markdown_file_exits_1(tmp_path: Path, line: str) -> None:
    repo = make_repo(tmp_path, {**BASE, "scripts/lint.py": line})
    result = run(repo, "CLAUDE.md")
    assert result.returncode == 1, result.stdout
    assert "scripts/lint.py:1" in result.stdout


def test_reader_of_the_parent_directory_exits_1(tmp_path: Path) -> None:
    repo = make_repo(
        tmp_path,
        {
            **BASE,
            "docs/questions/q1.md": "x\n",
            "check.py": 'for f in Path("docs/questions").iterdir():\n',
        },
    )
    assert run(repo, "docs/questions/q1.md").returncode == 1


def test_mentions_inside_other_markdown_are_ignored(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, {**BASE, "README.md": 'See "CLAUDE.md" and `*.md`.\n'})
    assert run(repo, "CLAUDE.md").returncode == 0


def test_dots_in_the_name_are_literal(tmp_path: Path) -> None:
    repo = make_repo(
        tmp_path,
        {**BASE, "my.notes.md": "x\n", "app/x.py": 'open("myXnotes.md")\n'},
    )
    assert run(repo, "my.notes.md").returncode == 0


def test_a_new_untracked_file_is_checked_too(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, {**BASE, "tests/t.py": 'read("NEW.md")\n'})
    (repo / "NEW.md").write_text("x\n")
    assert run(repo, "NEW.md").returncode == 1


def test_no_paths_exits_2(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, BASE)
    assert run(repo).returncode == 2


def test_outside_a_git_repo_exits_2(tmp_path: Path) -> None:
    (tmp_path / "x.md").write_text("x\n")
    assert run(tmp_path, "x.md").returncode == 2
