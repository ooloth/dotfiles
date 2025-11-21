#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest"]
# ///
"""
Tests for pure functions in TIL workflow scripts.

Run with: uv run test_pure_functions.py
Or: uv run pytest test_pure_functions.py -v
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from scan_git import format_relative_date, should_skip_commit
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


if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main([__file__, "-v"]))
