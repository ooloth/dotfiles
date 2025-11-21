#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest", "notion-client", "pydantic", "ruff", "mypy"]
# ///
"""
Tests for pure functions in TIL workflow scripts.

Run with: uv run test_pure_functions.py
Or: uv run pytest test_pure_functions.py -v
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from git.commits import Commit
from git.formatting import format_markdown, format_relative_date, should_skip_commit
from notion.blocks import extract_page_id, markdown_to_blocks
from notion.commits import get_assessed_commits_from_notion


class TestFormatRelativeDate:
    """Test relative date formatting."""

    def test_formats_recent_as_hours_or_just_now(self):
        from datetime import datetime
        now = datetime.now().isoformat() + "Z"
        result = format_relative_date(now)
        # Could be "just now" or "N hours ago" depending on timing
        assert "ago" in result or result == "just now"

    def test_formats_yesterday(self):
        from datetime import datetime, timedelta
        yesterday = (datetime.now() - timedelta(days=1)).isoformat() + "Z"
        result = format_relative_date(yesterday)
        assert result == "yesterday"

    def test_formats_days_ago(self):
        result = format_relative_date("2025-01-15T12:00:00Z")
        # Will be "N days ago" depending on current date
        assert "ago" in result

    def test_handles_invalid_date(self):
        result = format_relative_date("not-a-date")
        assert result == "unknown"

    def test_handles_empty_string(self):
        result = format_relative_date("")
        assert result == "unknown"


class TestShouldSkipCommit:
    """Test commit filtering logic."""

    def test_skips_dependabot(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="Bump dependency from 1.0 to 2.0",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123"
        )
        assert should_skip_commit(commit) is True

    def test_skips_bump_commits(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="bump version from 1.0 to 2.0",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123"
        )
        assert should_skip_commit(commit) is True

    def test_skips_merge_commits(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="merge pull request #123",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123"
        )
        assert should_skip_commit(commit) is True

    def test_keeps_normal_commits(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="fix: handle null values properly",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123"
        )
        assert should_skip_commit(commit) is False

    def test_keeps_feature_commits(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="feat: add new TIL workflow",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123"
        )
        assert should_skip_commit(commit) is False


class TestFormatMarkdown:
    """Test markdown formatting for commits."""

    def test_formats_empty_list(self):
        result = format_markdown([], 30, 0, 0)
        assert "Git commits from last 30 days:" in result
        assert "No commits found" in result

    def test_formats_all_already_reviewed(self):
        result = format_markdown([], 30, 0, 5)
        assert "Git commits from last 30 days:" in result
        assert "No new commits to assess" in result
        assert "5 commits already reviewed" in result

    def test_formats_single_commit_basic(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123456789",
            subject="feat: add new feature",
            body="",
            date="2 days ago",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=["src/main.py"],
            url="https://github.com/owner/repo/commit/abc123456789",
        )
        result = format_markdown([commit], 30, 1, 1)

        assert "Git commits from last 30 days:" in result
        assert "1. [owner/repo] feat: add new feature" in result
        assert "Hash: abc1234 (index: 0) | Date: 2 days ago" in result
        assert "Files: src/main.py" in result
        assert "URL: https://github.com/owner/repo/commit/abc123456789" in result

    def test_formats_commit_with_body(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123456789",
            subject="fix: handle edge case",
            body="This fixes an issue where null values weren't handled properly.",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=["src/handler.py"],
            url="https://github.com/owner/repo/commit/abc123456789",
        )
        result = format_markdown([commit], 30, 1, 1)

        assert "Body: This fixes an issue where null values weren't handled properly." in result

    def test_formats_commit_with_long_body(self):
        long_body = "a" * 250
        commit = Commit(
            hash="abc1234",
            full_hash="abc123456789",
            subject="feat: major refactor",
            body=long_body,
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=["src/main.py"],
            url="https://github.com/owner/repo/commit/abc123456789",
        )
        result = format_markdown([commit], 30, 1, 1)

        assert "Body: " + "a" * 200 + "..." in result
        assert len([line for line in result.split("\n") if "Body:" in line][0]) < 220

    def test_formats_commit_with_no_files(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123456789",
            subject="chore: update docs",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123456789",
        )
        result = format_markdown([commit], 30, 1, 1)

        assert "Files: (no files)" in result

    def test_formats_commit_with_many_files(self):
        files = [f"file{i}.py" for i in range(10)]
        commit = Commit(
            hash="abc1234",
            full_hash="abc123456789",
            subject="refactor: reorganize code",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=files,
            url="https://github.com/owner/repo/commit/abc123456789",
        )
        result = format_markdown([commit], 30, 1, 1)

        # Should show first 5 files
        assert "file0.py, file1.py, file2.py, file3.py, file4.py" in result
        # Should indicate there are more
        assert "(+5 more)" in result
        # Should NOT show file5 or later
        assert "file5.py" not in result

    def test_formats_multiple_commits(self):
        commits = [
            Commit(
                hash="abc1234",
                full_hash="abc123",
                subject="First commit",
                body="",
                date="2 days ago",
                iso_date="2025-01-15",
                repo="owner/repo1",
                files=["a.py"],
                url="https://github.com/owner/repo1/commit/abc123",
            ),
            Commit(
                hash="def5678",
                full_hash="def567",
                subject="Second commit",
                body="",
                date="yesterday",
                iso_date="2025-01-16",
                repo="owner/repo2",
                files=["b.py"],
                url="https://github.com/owner/repo2/commit/def567",
            ),
        ]
        result = format_markdown(commits, 7, 2, 2)

        assert "1. [owner/repo1] First commit" in result
        assert "Hash: abc1234 (index: 0)" in result
        assert "2. [owner/repo2] Second commit" in result
        assert "Hash: def5678 (index: 1)" in result

    def test_shows_review_status_when_some_already_reviewed(self):
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="New commit",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=["a.py"],
            url="https://github.com/owner/repo/commit/abc123",
        )
        result = format_markdown([commit], 30, 1, 5)

        assert "Git commits from last 30 days:" in result
        assert "(1 new, 4 already reviewed)" in result


class TestExtractPageId:
    """Test Notion URL page ID extraction."""

    def test_extracts_from_standard_url(self):
        url = "https://www.notion.so/Page-Title-abc123def456"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_extracts_from_url_with_query_params(self):
        url = "https://www.notion.so/Page-Title-abc123def456?v=xyz"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_extracts_from_short_url(self):
        url = "https://notion.so/abc123def456"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_handles_trailing_slash(self):
        url = "https://www.notion.so/Page-Title-abc123def456/"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_handles_empty_string(self):
        result = extract_page_id("")
        assert result == ""

    def test_extracts_uuid_with_dashes(self):
        # Notion IDs can have dashes in UUID format
        url = "https://www.notion.so/12345678-90ab-cdef-1234-567890abcdef"
        result = extract_page_id(url)
        # Should get the whole UUID including trailing segment
        assert len(result) > 0


def make_notion_page(commit_hash: str) -> dict:
    """Helper: create a mock Notion page with a commit hash."""
    return {
        "properties": {
            "Commit Hash": {
                "title": [{"plain_text": commit_hash}]
            }
        }
    }


def make_notion_response(
    hashes: list[str], has_more: bool = False, next_cursor: str | None = None
) -> dict:
    """Helper: create a mock Notion SDK response."""
    return {
        "results": [make_notion_page(h) for h in hashes],
        "has_more": has_more,
        "next_cursor": next_cursor
    }


def mock_notion_client(responses: list[dict]):
    """Helper: create a mock Notion client with predefined responses."""
    mock_client = MagicMock()
    mock_client.databases.query.side_effect = responses
    return mock_client


class TestGetAssessedCommitsFromNotion:
    """Test fetching assessed commits from Notion."""

    def test_returns_empty_set_when_no_token(self):
        with patch("notion.commits.get_op_secret", return_value=""):
            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_returns_commit_hashes_from_single_page(self):
        with patch("notion.commits.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            mock_client = mock_notion_client([
                make_notion_response(["abc123", "def456", "ghi789"])
            ])
            MockClient.return_value = mock_client

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456", "ghi789"}

    def test_handles_pagination(self):
        with patch("notion.commits.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            # First page with more results
            first_response = make_notion_response(
                ["abc123", "def456"],
                has_more=True,
                next_cursor="cursor-1"
            )
            # Second page, final
            second_response = make_notion_response(
                ["ghi789", "jkl012"],
                has_more=False
            )

            mock_client = mock_notion_client([first_response, second_response])
            MockClient.return_value = mock_client

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456", "ghi789", "jkl012"}
            assert mock_client.databases.query.call_count == 2

    def test_handles_client_error_gracefully(self):
        with patch("notion.commits.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            MockClient.side_effect = Exception("Connection error")

            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_handles_query_error_gracefully(self):
        with patch("notion.commits.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            mock_client = MagicMock()
            mock_client.databases.query.side_effect = Exception("Query error")
            MockClient.return_value = mock_client

            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_skips_pages_without_commit_hash(self):
        with patch("notion.commits.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            response = {
                "results": [
                    make_notion_page("abc123"),
                    {"properties": {"Commit Hash": {"title": []}}},  # Empty title
                    make_notion_page("def456"),
                ],
                "has_more": False,
                "next_cursor": None
            }

            mock_client = mock_notion_client([response])
            MockClient.return_value = mock_client

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456"}


class TestMarkdownToBlocks:
    """Test markdown to Notion blocks conversion."""

    def test_converts_code_blocks(self):
        markdown = "```python\nprint('hello')\n```"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 1
        assert blocks[0]["type"] == "code"
        assert blocks[0]["code"]["language"] == "python"
        assert blocks[0]["code"]["rich_text"][0]["text"]["content"] == "print('hello')"

    def test_maps_language_aliases(self):
        markdown = "```js\nconsole.log('test')\n```"
        blocks = markdown_to_blocks(markdown)

        assert blocks[0]["code"]["language"] == "javascript"

    def test_converts_headings(self):
        markdown = "# H1\n## H2\n### H3"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 3
        assert blocks[0]["type"] == "heading_1"
        assert blocks[1]["type"] == "heading_2"
        assert blocks[2]["type"] == "heading_3"

    def test_converts_bullet_lists(self):
        markdown = "- Item 1\n- Item 2"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 2
        assert blocks[0]["type"] == "bulleted_list_item"
        assert blocks[0]["bulleted_list_item"]["rich_text"][0]["text"]["content"] == "Item 1"

    def test_converts_numbered_lists(self):
        markdown = "1. First\n2. Second"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 2
        assert blocks[0]["type"] == "numbered_list_item"
        assert blocks[1]["type"] == "numbered_list_item"

    def test_converts_paragraphs(self):
        markdown = "This is a paragraph"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 1
        assert blocks[0]["type"] == "paragraph"
        assert blocks[0]["paragraph"]["rich_text"][0]["text"]["content"] == "This is a paragraph"

    def test_handles_empty_lines(self):
        markdown = "Line 1\n\nLine 2"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 3
        assert blocks[1]["type"] == "paragraph"
        assert blocks[1]["paragraph"]["rich_text"] == []

    def test_handles_multiline_code_blocks(self):
        markdown = "```python\nline1\nline2\nline3\n```"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 1
        assert "line1\nline2\nline3" in blocks[0]["code"]["rich_text"][0]["text"]["content"]


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v"]))
