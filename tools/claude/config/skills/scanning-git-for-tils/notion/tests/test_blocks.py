#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pytest"]
# ///
"""Tests for Notion blocks utilities."""

from __future__ import annotations

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from notion.blocks import extract_page_id, markdown_to_blocks


class TestExtractPageId:
    """Test Notion URL page ID extraction."""

    def test_extracts_from_standard_url(self) -> None:
        url = "https://www.notion.so/Page-Title-abc123def456"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_extracts_from_url_with_query_params(self) -> None:
        url = "https://www.notion.so/Page-Title-abc123def456?v=xyz"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_extracts_from_short_url(self) -> None:
        url = "https://notion.so/abc123def456"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_handles_trailing_slash(self) -> None:
        url = "https://www.notion.so/Page-Title-abc123def456/"
        result = extract_page_id(url)
        assert result == "abc123def456"

    def test_handles_empty_string(self) -> None:
        result = extract_page_id("")
        assert result == ""

    def test_extracts_uuid_with_dashes(self) -> None:
        # Notion IDs can have dashes in UUID format
        url = "https://www.notion.so/12345678-90ab-cdef-1234-567890abcdef"
        result = extract_page_id(url)
        # Should get the whole UUID including trailing segment
        assert len(result) > 0


class TestMarkdownToBlocks:
    """Test markdown to Notion blocks conversion."""

    def test_converts_code_blocks(self) -> None:
        markdown = "```python\nprint('hello')\n```"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 1
        assert blocks[0]["type"] == "code"
        assert blocks[0]["code"]["language"] == "python"
        assert blocks[0]["code"]["rich_text"][0]["text"]["content"] == "print('hello')"

    def test_maps_language_aliases(self) -> None:
        markdown = "```js\nconsole.log('test')\n```"
        blocks = markdown_to_blocks(markdown)

        assert blocks[0]["code"]["language"] == "javascript"

    def test_converts_headings(self) -> None:
        markdown = "# H1\n## H2\n### H3"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 3
        assert blocks[0]["type"] == "heading_1"
        assert blocks[1]["type"] == "heading_2"
        assert blocks[2]["type"] == "heading_3"

    def test_converts_bullet_lists(self) -> None:
        markdown = "- Item 1\n- Item 2"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 2
        assert blocks[0]["type"] == "bulleted_list_item"
        assert blocks[0]["bulleted_list_item"]["rich_text"][0]["text"]["content"] == "Item 1"

    def test_converts_numbered_lists(self) -> None:
        markdown = "1. First\n2. Second"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 2
        assert blocks[0]["type"] == "numbered_list_item"
        assert blocks[1]["type"] == "numbered_list_item"

    def test_converts_paragraphs(self) -> None:
        markdown = "This is a paragraph"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 1
        assert blocks[0]["type"] == "paragraph"
        assert blocks[0]["paragraph"]["rich_text"][0]["text"]["content"] == "This is a paragraph"

    def test_handles_empty_lines(self) -> None:
        markdown = "Line 1\n\nLine 2"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 3
        assert blocks[1]["type"] == "paragraph"
        assert blocks[1]["paragraph"]["rich_text"] == []

    def test_handles_multiline_code_blocks(self) -> None:
        markdown = "```python\nline1\nline2\nline3\n```"
        blocks = markdown_to_blocks(markdown)

        assert len(blocks) == 1
        assert "line1\nline2\nline3" in blocks[0]["code"]["rich_text"][0]["text"]["content"]


if __name__ == "__main__":
    import pytest

    sys.exit(pytest.main([__file__, "-v"]))
