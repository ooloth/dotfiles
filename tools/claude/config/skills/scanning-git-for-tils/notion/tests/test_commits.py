#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest", "notion-client", "pydantic"]
# ///
"""Tests for Notion commits tracking."""

from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import patch

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from notion.commits import get_assessed_commits_from_notion


def make_notion_page(commit_hash: str) -> dict:
    """Helper: create a mock Notion page with a commit hash."""
    return {
        "id": f"page-{commit_hash}",
        "url": f"https://notion.so/page-{commit_hash}",
        "properties": {"Commit Hash": {"title": [{"plain_text": commit_hash}]}},
    }


def make_notion_response(
    hashes: list[str], has_more: bool = False, next_cursor: str | None = None
) -> dict:
    """Helper: create a mock Notion SDK response."""
    return {
        "results": [make_notion_page(h) for h in hashes],
        "has_more": has_more,
        "next_cursor": next_cursor,
    }


def mock_collect_paginated_api(pages: list[dict]) -> list[dict]:
    """Helper: mock collect_paginated_api to return all pages as a flat list."""
    all_results: list[dict] = []
    for page_response in pages:
        all_results.extend(page_response["results"])
    return all_results


class TestGetAssessedCommitsFromNotion:
    """Test fetching assessed commits from Notion."""

    def test_returns_empty_set_when_no_token(self) -> None:
        with patch("notion.commits.get_op_secret", side_effect=RuntimeError("Failed")):
            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_returns_commit_hashes_from_single_page(self) -> None:
        with (
            patch("notion.commits.get_op_secret", return_value="fake-token"),
            patch("notion_client.Client"),
            patch("notion_client.helpers.collect_paginated_api") as mock_paginate,
        ):
            pages = [make_notion_response(["abc123", "def456", "ghi789"])]
            mock_paginate.return_value = mock_collect_paginated_api(pages)

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456", "ghi789"}

    def test_handles_pagination(self) -> None:
        with (
            patch("notion.commits.get_op_secret", return_value="fake-token"),
            patch("notion_client.Client"),
            patch("notion_client.helpers.collect_paginated_api") as mock_paginate,
        ):
            # First page with more results
            first_response = make_notion_response(
                ["abc123", "def456"], has_more=True, next_cursor="cursor-1"
            )
            # Second page, final
            second_response = make_notion_response(["ghi789", "jkl012"], has_more=False)

            # collect_paginated_api handles pagination internally, returns all results
            pages = [first_response, second_response]
            mock_paginate.return_value = mock_collect_paginated_api(pages)

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456", "ghi789", "jkl012"}

    def test_handles_client_error_gracefully(self) -> None:
        with (
            patch("notion.commits.get_op_secret", return_value="fake-token"),
            patch("notion_client.Client") as MockClient,
        ):
            MockClient.side_effect = Exception("Connection error")

            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_handles_query_error_gracefully(self) -> None:
        with (
            patch("notion.commits.get_op_secret", return_value="fake-token"),
            patch("notion_client.Client"),
            patch("notion_client.helpers.collect_paginated_api") as mock_paginate,
        ):
            mock_paginate.side_effect = Exception("Query error")

            result = get_assessed_commits_from_notion()
            assert result == set()

    def test_skips_pages_without_commit_hash(self) -> None:
        with (
            patch("notion.commits.get_op_secret", return_value="fake-token"),
            patch("notion_client.Client"),
            patch("notion_client.helpers.collect_paginated_api") as mock_paginate,
        ):
            response = {
                "results": [
                    make_notion_page("abc123"),
                    {  # Empty title
                        "id": "page-empty",
                        "url": "https://notion.so/page-empty",
                        "properties": {"Commit Hash": {"title": []}},
                    },
                    make_notion_page("def456"),
                ],
                "has_more": False,
                "next_cursor": None,
            }

            mock_paginate.return_value = mock_collect_paginated_api([response])

            result = get_assessed_commits_from_notion()
            assert result == {"abc123", "def456"}


if __name__ == "__main__":
    import pytest

    sys.exit(pytest.main([__file__, "-v"]))
