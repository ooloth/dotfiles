#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest"]
# ///
"""Tests for git formatting utilities."""

from __future__ import annotations

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from git.formatting import format_markdown, format_relative_date, should_skip_commit
from git.types import Commit


class TestFormatRelativeDate:
    """Test relative date formatting."""

    def test_formats_recent_as_hours_or_just_now(self) -> None:
        from datetime import datetime

        now = datetime.now().isoformat() + "Z"
        result = format_relative_date(now)
        # Could be "just now" or "N hours ago" depending on timing
        assert "ago" in result or result == "just now"

    def test_formats_yesterday(self) -> None:
        from datetime import datetime, timedelta

        yesterday = (datetime.now() - timedelta(days=1)).isoformat() + "Z"
        result = format_relative_date(yesterday)
        assert result == "yesterday"

    def test_formats_days_ago(self) -> None:
        result = format_relative_date("2025-01-15T12:00:00Z")
        # Will be "N days ago" depending on current date
        assert "ago" in result

    def test_handles_invalid_date(self) -> None:
        result = format_relative_date("not-a-date")
        assert result == "unknown"

    def test_handles_empty_string(self) -> None:
        result = format_relative_date("")
        assert result == "unknown"


class TestShouldSkipCommit:
    """Test commit filtering logic."""

    def test_skips_dependabot(self) -> None:
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="Bump dependency from 1.0 to 2.0",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123",
        )
        assert should_skip_commit(commit) is True

    def test_skips_bump_commits(self) -> None:
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="bump version from 1.0 to 2.0",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123",
        )
        assert should_skip_commit(commit) is True

    def test_skips_merge_commits(self) -> None:
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="merge pull request #123",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123",
        )
        assert should_skip_commit(commit) is True

    def test_keeps_normal_commits(self) -> None:
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="fix: handle null values properly",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123",
        )
        assert should_skip_commit(commit) is False

    def test_keeps_feature_commits(self) -> None:
        commit = Commit(
            hash="abc1234",
            full_hash="abc123",
            subject="feat: add new TIL workflow",
            body="",
            date="yesterday",
            iso_date="2025-01-15",
            repo="owner/repo",
            files=[],
            url="https://github.com/owner/repo/commit/abc123",
        )
        assert should_skip_commit(commit) is False


class TestFormatMarkdown:
    """Test markdown formatting for commits."""

    def test_formats_empty_list(self) -> None:
        result = format_markdown([], 30, 0, 0)
        assert "Git commits from last 30 days:" in result
        assert "No commits found" in result

    def test_formats_all_already_reviewed(self) -> None:
        result = format_markdown([], 30, 0, 5)
        assert "Git commits from last 30 days:" in result
        assert "No new commits to assess" in result
        assert "5 commits already reviewed" in result

    def test_formats_single_commit_basic(self) -> None:
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

    def test_formats_commit_with_body(self) -> None:
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

    def test_formats_commit_with_long_body(self) -> None:
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

    def test_formats_commit_with_no_files(self) -> None:
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

    def test_formats_commit_with_many_files(self) -> None:
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

    def test_formats_multiple_commits(self) -> None:
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

    def test_shows_review_status_when_some_already_reviewed(self) -> None:
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


if __name__ == "__main__":
    import pytest

    sys.exit(pytest.main([__file__, "-v"]))
