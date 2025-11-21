#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest", "notion-client"]
# ///
"""
Tests for pure functions in TIL workflow scripts.

Run with: uv run test_pure_functions.py
Or: uv run pytest test_pure_functions.py -v
"""

import sys
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from scan_git import format_relative_date, should_skip_commit, get_assessed_commits_from_notion
from publish_til import extract_page_id


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
        commit = {"subject": "Bump dependency from 1.0 to 2.0", "full_hash": "abc123"}
        assert should_skip_commit(commit) is True

    def test_skips_bump_commits(self):
        commit = {"subject": "bump version from 1.0 to 2.0", "full_hash": "abc123"}
        assert should_skip_commit(commit) is True

    def test_skips_merge_commits(self):
        commit = {"subject": "merge pull request #123", "full_hash": "abc123"}
        assert should_skip_commit(commit) is True

    def test_keeps_normal_commits(self):
        commit = {"subject": "fix: handle null values properly", "full_hash": "abc123"}
        assert should_skip_commit(commit) is False

    def test_keeps_feature_commits(self):
        commit = {"subject": "feat: add new TIL workflow", "full_hash": "abc123"}
        assert should_skip_commit(commit) is False


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


def make_notion_response(hashes: list[str], has_more: bool = False, next_cursor: str | None = None) -> dict:
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
        with patch("scan_git.get_op_secret", return_value=""):
            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_returns_commit_hashes_from_single_page(self):
        with patch("scan_git.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            mock_client = mock_notion_client([
                make_notion_response(["abc123", "def456", "ghi789"])
            ])
            MockClient.return_value = mock_client

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456", "ghi789"}

    def test_handles_pagination(self):
        with patch("scan_git.get_op_secret", return_value="fake-token"), \
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
        with patch("scan_git.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            MockClient.side_effect = Exception("Connection error")

            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_handles_query_error_gracefully(self):
        with patch("scan_git.get_op_secret", return_value="fake-token"), \
             patch("notion_client.Client") as MockClient:

            mock_client = MagicMock()
            mock_client.databases.query.side_effect = Exception("Query error")
            MockClient.return_value = mock_client

            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_skips_pages_without_commit_hash(self):
        with patch("scan_git.get_op_secret", return_value="fake-token"), \
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


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v"]))
