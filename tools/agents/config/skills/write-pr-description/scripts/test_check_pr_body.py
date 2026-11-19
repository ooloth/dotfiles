"""Tests for check_pr_body.py.

The checks are pure functions, so most tests call them in-process on small bodies and on HTML
written by hand, copied from what GitHub's markdown API returned for the same markdown. `main` is
run with a fake gh, so no test calls gh or the network.

Run with `bash scripts/checks/tests.bash <this file>` from the repo root, or
`uv run --with pytest --with 'markdown-it-py>=4,<5' pytest <this file>`.
"""

import importlib.util
import json
import sys
from pathlib import Path

import pytest

SCRIPT = Path(__file__).with_name("check_pr_body.py")

spec = importlib.util.spec_from_file_location("check_pr_body", SCRIPT)
assert spec is not None and spec.loader is not None
check_pr_body = importlib.util.module_from_spec(spec)
sys.modules["check_pr_body"] = check_pr_body
spec.loader.exec_module(check_pr_body)

REPO = "owner/repo"


def kinds(problems: list) -> list[str]:
    return [problem.kind for problem in problems]


def lines_of(problems: list, kind: str) -> list[int]:
    return [problem.where for problem in problems if problem.kind == kind]


# A row as the skill lays it out, and the HTML GitHub's markdown API returned for it.

GOOD_ROW_HTML = """<ol dir="auto">
<li>
<details>
<summary><b>🛠️ Setup</b></summary>
<h4 dir="auto">💻 The app</h4>
<ul class="contains-task-list">
<li class="task-list-item">
<p dir="auto"><input type="checkbox" disabled="" class="task-list-item-checkbox"> Start it:</p>
<div class="highlight highlight-source-shell" dir="auto"><pre class="notranslate">make dev</pre></div>
</li>
</ul>
</details>
</li>
</ol>
"""

# The Setup row's code block with its lines indented less than its fence, as GitHub rendered it:
# the block is empty, its lines become a paragraph, and the closing fence opens a new block.
UNDER_INDENTED_HTML = """<ol dir="auto">
<li>
<details>
<summary><b>🛠️ Setup</b></summary>
<h4 dir="auto">💻 Thing</h4>
<ul class="contains-task-list">
<li class="task-list-item">
<p dir="auto"><input type="checkbox" disabled="" class="task-list-item-checkbox"> Start it:</p>
<div class="highlight highlight-source-shell" dir="auto"><pre class="notranslate"></pre></div>
</li>
</ul>
<p dir="auto">make dev<br>
make other</p>
<pre class="notranslate"><code class="notranslate">
- [ ] Next step
</code></pre>
</details></li>
</ol>
"""

# `- <summary>📄 x</summary>`, as GitHub rendered it.
SUMMARY_AS_BULLET_HTML = """<ol dir="auto">
<li>
<details>
- <summary>📄 x</summary>
<h4 dir="auto">🧾 Proven by</h4>
<ul dir="auto">
<li>The run below</li>
</ul>
</details>
</li>
</ol>
"""


class TestRenderedHtml:
    def test_a_row_laid_out_as_the_skill_says_passes(self) -> None:
        assert check_pr_body.check_html(GOOD_ROW_HTML) == []

    def test_code_block_indented_less_than_its_fence_is_reported_empty_and_outside_its_step(
        self,
    ) -> None:
        problems = check_pr_body.check_html(UNDER_INDENTED_HTML)
        assert "empty code block" in kinds(problems)
        assert "code outside its step" in kinds(problems)
        assert all('"🛠️ Setup"' in problem.what for problem in problems)

    def test_summary_turned_into_a_bullet_is_reported(self) -> None:
        problems = check_pr_body.check_html(SUMMARY_AS_BULLET_HTML)
        assert kinds(problems) == ["text before summary"]
        assert '"-"' in problems[0].what

    def test_details_outside_a_list_item_is_reported(self) -> None:
        html = "<details>\n<summary>📄 x</summary>\n<p>y</p>\n</details>\n"
        assert kinds(check_pr_body.check_html(html)) == ["row outside a list item"]

    def test_fence_shown_as_text_is_reported(self) -> None:
        html = '<p dir="auto">Stray ``` here</p>'
        assert kinds(check_pr_body.check_html(html)) == ["fence shown as text"]

    @pytest.mark.parametrize(
        "html",
        ["<pre>```sh\nls\n```</pre>", "<p>Write <code>```</code> to open a fence</p>"],
        ids=["code block", "inline code"],
    )
    def test_fence_characters_inside_code_pass(self, html: str) -> None:
        assert check_pr_body.check_html(html) == []

    def test_code_block_after_a_heading_that_follows_a_checklist_passes(self) -> None:
        html = (
            '<ul class="contains-task-list"><li class="task-list-item">Run it</li></ul>'
            "<h4>👀 What I saw</h4><pre>output</pre>"
        )
        assert check_pr_body.check_html(html) == []

    def test_code_block_directly_after_a_checklist_is_reported(self) -> None:
        html = (
            '<ul class="contains-task-list"><li class="task-list-item">Run it</li></ul>'
            '<div class="highlight"><pre>ls</pre></div>'
        )
        assert kinds(check_pr_body.check_html(html)) == ["code outside its step"]

    def test_summary_that_left_its_row_is_reported_by_its_text(self) -> None:
        problems = check_pr_body.check_html(SUMMARY_OUTSIDE_ITS_ROW_HTML)
        assert kinds(problems) == ["summary outside its row"]
        assert '"📄 Row ten\'s behaviour"' in problems[0].what


# Rows 9 and 10 of a real description as GitHub's markdown API rendered them, trimmed and with
# their summaries renamed. Row 10 sat under `10. <details>` with its content indented three spaces,
# as for `9. `, so it fell out of the list item: GitHub gave the emptied <details> its own
# `<summary>Details</summary>`, and the row's summary landed after the list.
SUMMARY_OUTSIDE_ITS_ROW_HTML = """<ol dir="auto">
<li>
<details>
<summary>📄 Row nine's behaviour</summary>
<h4 dir="auto">🧾 Proven by</h4>
<ul dir="auto">
<li>The run below</li>
</ul>
</details>
</li>
<li>
<details><summary>Details</summary>
</details></li>
</ol>
   <summary>📄 Row ten's behaviour</summary>
<h4 dir="auto">🧾 Proven by</h4>
<ul dir="auto">
<li>The run below</li>
</ul>
"""


GOOD_BODY = """## ✅ What

- Adds a toggle, using `make dev` to try it

## 🤔 Why

- Users asked for it

## 👩‍🔬 How to verify

1. <details>
   <summary><b>🛠️ Setup</b></summary>

   - [ ] Start the app:

     ```sh
     make dev
     ```

   </details>

2. **✨ What's new**

   1. <details>
      <summary>📄 The toggle appears</summary>

      #### 🧾 Proven by

      - The run below
      - In CI, `test_toggle`

      #### 🔍 Verification steps

      - [ ] Run:

        ```sh
        curl -s localhost:8000/toggle
        ```

      #### 👀 What I saw

      - It printed:

        ```text
        on
        ```

      </details>

3. <details>
   <summary><b>🚀 After merge</b></summary>

   - [ ] Expect the toggle in production

   </details>

## 🔖 Related links

- [Jira task: PROJ-1](https://jira.example.com/browse/PROJ-1)
"""


class TestMarkdownSource:
    def test_a_body_laid_out_as_the_skill_says_passes(self) -> None:
        assert check_pr_body.check_markdown(GOOD_BODY) == []

    def test_summary_turned_into_a_bullet_is_reported_on_its_line(self) -> None:
        body = "1. <details>\n   - <summary>📄 x</summary>\n\n   </details>\n"
        assert lines_of(check_pr_body.check_markdown(body), "tag on a list item") == [2]

    @pytest.mark.parametrize(
        "line",
        ["- <details>", "* </details>", "1. <summary>x</summary>", "2. </details>"],
    )
    def test_tag_on_a_list_marker_line_is_reported(self, line: str) -> None:
        assert kinds(check_pr_body.check_markdown(line + "\n")) == ["tag on a list item"]

    @pytest.mark.parametrize("line", ["1. <details>", "   </details>", "   <summary>x</summary>"])
    def test_a_numbered_details_and_unmarked_tags_pass(self, line: str) -> None:
        assert check_pr_body.check_markdown(line + "\n") == []

    def test_a_tag_on_a_list_line_inside_a_code_block_passes(self) -> None:
        assert (
            check_pr_body.check_markdown("## Notes\n\n```md\n- <summary>x</summary>\n```\n") == []
        )

    def test_code_block_in_what_is_reported(self) -> None:
        body = "## ✅ What\n\n- Adds x:\n\n  ```sh\n  make x\n  ```\n\n## 🤔 Why\n\n- y\n"
        assert lines_of(check_pr_body.check_markdown(body), "code block in What") == [5]

    def test_code_block_after_what_ends_passes(self) -> None:
        body = "## ✅ What\n\n- Adds x\n\n## 👩‍🔬 How to verify\n\n```sh\nmake x\n```\n"
        assert check_pr_body.check_markdown(body) == []

    def test_proven_by_ending_in_a_plain_paragraph_is_reported(self) -> None:
        body = (
            "#### 🧾 Proven by\n\n- The run below\n\nSeen at `abc123`.\n\n"
            "#### 🔍 Verification steps\n\nNot a bullet, but not under Proven by.\n"
        )
        assert lines_of(check_pr_body.check_markdown(body), "Proven by line not a bullet") == [5]

    def test_proven_by_ends_at_the_rows_closing_tag(self) -> None:
        body = "#### 🧾 Proven by\n\n- The run below\n\n</details>\n\nA paragraph after the row.\n"
        assert check_pr_body.check_markdown(body) == []

    def test_property_number_is_reported(self) -> None:
        body = "- Holds P1 and P12\n"
        assert lines_of(check_pr_body.check_markdown(body), "property number") == [1, 1]

    @pytest.mark.parametrize(
        "text",
        [
            "- HTTP1 and P1x and p1\n",
            "```\nP1\n```\n",
            "- P95 latency, P50, P75, P90, P99 and P999 stay flat, and P0 bugs\n",
        ],
    )
    def test_text_that_is_not_a_property_number_passes(self, text: str) -> None:
        assert check_pr_body.check_markdown(text) == []

    @pytest.mark.parametrize(
        "target", ["/Users/me/notes.md", "~/notes.md", "file:///Users/me/notes.md"]
    )
    def test_link_to_a_local_path_is_reported(self, target: str) -> None:
        body = f"- See [notes]({target})\n"
        assert kinds(check_pr_body.check_markdown(body)) == ["local link"]

    def test_link_to_a_web_page_passes(self) -> None:
        assert check_pr_body.check_markdown("- See [notes](https://example.com/a)\n") == []

    def test_pre_merge_heading_without_an_after_merge_row_is_reported(self) -> None:
        body = "## 👩‍🔬 How to verify\n\n### Pre-merge\n\n- [ ] Run it\n"
        assert lines_of(check_pr_body.check_markdown(body), "Pre-merge heading") == [3]

    def test_pre_merge_heading_with_an_after_merge_row_passes(self) -> None:
        body = (
            "### Pre-merge\n\n1. <details>\n   <summary><b>🚀 After merge</b></summary>\n\n"
            "   - [ ] Check prod\n\n   </details>\n"
        )
        assert check_pr_body.check_markdown(body) == []

    def test_line_numbers_count_windows_line_endings_once(self) -> None:
        body = "- a\r\n- b\r\n- P3\r\n"
        assert lines_of(check_pr_body.check_markdown(body), "property number") == [3]


RAN = """make dev
curl -s localhost:8000/toggle
"""


class TestCommands:
    def test_every_step_block_that_was_run_passes(self) -> None:
        assert check_pr_body.check_commands(GOOD_BODY, RAN, "ran.txt") == []

    def test_verification_step_block_that_was_not_run_is_reported(self) -> None:
        problems = check_pr_body.check_commands(GOOD_BODY, "make dev\n", "ran.txt")
        assert kinds(problems) == ["command not run"]
        assert "Verification steps" in problems[0].what
        assert "ran.txt" in problems[0].what

    def test_setup_block_that_was_not_run_is_reported(self) -> None:
        problems = check_pr_body.check_commands(GOOD_BODY, RAN.replace("make dev", ""), "ran.txt")
        assert kinds(problems) == ["command not run"]
        assert "Setup" in problems[0].what

    def test_clean_up_block_that_was_not_run_is_reported(self) -> None:
        body = (
            "1. <details>\n   <summary><b>🧹 Clean up</b></summary>\n\n   - [ ] Stop it:\n\n"
            "     ```sh\n     tmux kill-session -t x\n     ```\n\n   </details>\n"
        )
        assert kinds(check_pr_body.check_commands(body, "", "ran.txt")) == ["command not run"]

    def test_what_i_saw_output_is_not_held_to_the_commands_file(self) -> None:
        # GOOD_BODY's What I saw block holds `on`, which is not among the commands.
        assert "on" not in RAN.split()
        assert check_pr_body.check_commands(GOOD_BODY, RAN, "ran.txt") == []

    def test_a_multi_line_block_must_appear_whole(self) -> None:
        body = "#### 🔍 Verification steps\n\n- [ ] Run:\n\n  ```sh\n  first\n  second\n  ```\n"
        assert check_pr_body.check_commands(body, "first\nsecond\n", "ran.txt") == []
        assert kinds(check_pr_body.check_commands(body, "first\nother\nsecond\n", "ran.txt")) == [
            "command not run"
        ]

    def test_trailing_whitespace_is_ignored(self) -> None:
        body = "#### 🔍 Verification steps\n\n```sh\nls -la   \n```\n"
        assert check_pr_body.check_commands(body, "ls -la\r\n", "ran.txt") == []


class TestLiveCopy:
    def test_an_unchanged_live_body_passes(self) -> None:
        assert check_pr_body.check_live_copy("a\nb\n", "a  \r\nb", 7, "saved.md") == []

    def test_a_body_edited_since_it_was_read_is_reported(self) -> None:
        problems = check_pr_body.check_live_copy("a\nb\n", "a\nb\n- [x] Checked by Sam\n", 7, "s")
        assert kinds(problems) == ["live body changed"]
        assert "someone edited it" in problems[0].what
        assert "merge their change" in problems[0].fix


class FakeGh:
    """Answers gh calls from canned output, and records each call."""

    def __init__(self, html: str = GOOD_ROW_HTML, live: str | None = None, fail: str = "") -> None:
        self.html = html
        self.live = live
        self.fail = fail
        self.calls: list[tuple[list[str], str | None]] = []

    def __call__(self, args: list[str], stdin: str | None):
        self.calls.append((args, stdin))
        if self.fail and self.fail in args:
            return check_pr_body.CouldNotRun(f"gh {self.fail} failed")
        if args[:2] == ["api", "markdown"]:
            return check_pr_body.GhOutput(self.html)
        if args[:2] == ["pr", "view"] and self.live is not None:
            return check_pr_body.GhOutput(self.live)
        raise AssertionError(f"unexpected gh call {args}")


def write(tmp_path: Path, name: str, text: str) -> Path:
    path = tmp_path / name
    path.write_text(text)
    return path


class TestMain:
    def test_a_passing_body_exits_0(self, tmp_path: Path, capsys: pytest.CaptureFixture) -> None:
        body = write(tmp_path, "body.md", GOOD_BODY)
        assert check_pr_body.main([str(body), "--repo", REPO], FakeGh()) == 0
        assert "every check passed" in capsys.readouterr().out

    def test_the_body_is_rendered_as_gfm_in_the_repos_context(self, tmp_path: Path) -> None:
        gh = FakeGh()
        check_pr_body.main([str(write(tmp_path, "body.md", GOOD_BODY)), "--repo", REPO], gh)
        args, stdin = gh.calls[0]
        assert args == ["api", "markdown", "--input", "-"]
        assert json.loads(stdin or "") == {"text": GOOD_BODY, "mode": "gfm", "context": REPO}

    def test_problems_exit_1_with_one_line_each_and_the_sentinel(
        self, tmp_path: Path, capsys: pytest.CaptureFixture
    ) -> None:
        body = write(tmp_path, "body.md", "- Holds P1\n")
        gh = FakeGh(html=SUMMARY_AS_BULLET_HTML)
        assert check_pr_body.main([str(body), "--repo", REPO], gh) == 1
        out = capsys.readouterr().out.splitlines()
        assert out[0].startswith(f"{body}:1: property number: ")
        assert out[1].startswith(f"{body}:rendered: text before summary: ")
        assert out[-1].endswith("post nothing until then")

    def test_a_failed_render_exits_2_even_with_other_problems_found(
        self, tmp_path: Path, capsys: pytest.CaptureFixture
    ) -> None:
        body = write(tmp_path, "body.md", "- Holds P1\n")
        assert check_pr_body.main([str(body), "--repo", REPO], FakeGh(fail="markdown")) == 2
        assert "rendered checks did not run" in capsys.readouterr().err

    def test_an_unreadable_body_exits_2(
        self, tmp_path: Path, capsys: pytest.CaptureFixture
    ) -> None:
        missing = tmp_path / "missing.md"
        assert check_pr_body.main([str(missing), "--repo", REPO], FakeGh()) == 2
        assert str(missing) in capsys.readouterr().err

    def test_an_unreadable_commands_file_exits_2(self, tmp_path: Path) -> None:
        body = write(tmp_path, "body.md", GOOD_BODY)
        argv = [str(body), "--repo", REPO, "--commands", str(tmp_path / "missing.txt")]
        assert check_pr_body.main(argv, FakeGh()) == 2

    def test_a_commands_file_missing_a_step_exits_1(self, tmp_path: Path) -> None:
        body = write(tmp_path, "body.md", GOOD_BODY)
        ran = write(tmp_path, "ran.txt", "make dev\n")
        assert (
            check_pr_body.main([str(body), "--repo", REPO, "--commands", str(ran)], FakeGh()) == 1
        )

    def test_a_live_body_edited_since_it_was_read_exits_1(
        self, tmp_path: Path, capsys: pytest.CaptureFixture
    ) -> None:
        body = write(tmp_path, "body.md", GOOD_BODY)
        saved = write(tmp_path, "saved.md", GOOD_BODY)
        gh = FakeGh(live=GOOD_BODY + "\nA note Sam added\n")
        argv = [str(body), "--repo", REPO, "--live-copy", str(saved), "--pr", "7"]
        assert check_pr_body.main(argv, gh) == 1
        assert f"{body}:live: live body changed: PR #7" in capsys.readouterr().out
        assert gh.calls[1][0] == ["pr", "view", "7", "-R", REPO, "--json", "body", "-q", ".body"]

    def test_an_unchanged_live_body_exits_0(self, tmp_path: Path) -> None:
        body = write(tmp_path, "body.md", GOOD_BODY)
        saved = write(tmp_path, "saved.md", GOOD_BODY)
        argv = [str(body), "--repo", REPO, "--live-copy", str(saved), "--pr", "7"]
        assert check_pr_body.main(argv, FakeGh(live=GOOD_BODY)) == 0

    def test_a_failed_live_fetch_exits_2(self, tmp_path: Path) -> None:
        body = write(tmp_path, "body.md", GOOD_BODY)
        argv = [str(body), "--repo", REPO, "--live-copy", str(body), "--pr", "7"]
        assert check_pr_body.main(argv, FakeGh(fail="view")) == 2

    @pytest.mark.parametrize(
        "extra",
        [["--pr", "7"], ["--live-copy", "saved.md"], ["--pr", "0", "--live-copy", "s.md"]],
        ids=["pr alone", "live copy alone", "pr not a number"],
    )
    def test_bad_arguments_exit_2_before_any_gh_call(self, extra: list[str]) -> None:
        gh = FakeGh()
        with pytest.raises(SystemExit) as exit_info:
            check_pr_body.main(["body.md", "--repo", REPO, *extra], gh)
        assert exit_info.value.code == 2
        assert gh.calls == []

    def test_a_repo_not_shaped_owner_slash_name_exits_2(self) -> None:
        with pytest.raises(SystemExit) as exit_info:
            check_pr_body.main(["body.md", "--repo", "justname"], FakeGh())
        assert exit_info.value.code == 2


def test_gh_missing_from_path_could_not_run(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("PATH", str(tmp_path))
    result = check_pr_body.run_gh(["api", "markdown"], "{}")
    assert isinstance(result, check_pr_body.CouldNotRun)
    assert "gh is not installed" in result.reason
