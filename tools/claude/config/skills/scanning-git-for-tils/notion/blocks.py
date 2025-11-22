"""Notion block conversion utilities."""

from __future__ import annotations


def _map_language_alias(language: str) -> str:
    """Map common language names to Notion's expected values."""
    lang_map = {
        "": "plain text",
        "js": "javascript",
        "ts": "typescript",
        "py": "python",
        "sh": "shell",
        "bash": "shell",
        "zsh": "shell",
    }
    return lang_map.get(language, language) or "plain text"


def _create_code_block(lines: list[str], start_index: int) -> tuple[dict, int]:
    """Create a code block from markdown fenced code.

    Returns: (block dict, new index after closing ```)
    """
    language = lines[start_index].strip()[3:].strip()
    language = _map_language_alias(language)

    code_lines = []
    i = start_index + 1

    # Collect all lines until closing ```
    while i < len(lines):
        if lines[i].strip().startswith("```"):
            break
        code_lines.append(lines[i])
        i += 1

    code_content = "\n".join(code_lines)
    block = {
        "type": "code",
        "code": {
            "rich_text": [{"type": "text", "text": {"content": code_content}}],
            "language": language,
        },
    }

    return block, i + 1


def _create_heading_block(line: str) -> dict | None:
    """Create a heading block from markdown heading syntax.

    Returns: block dict or None if not a heading
    """
    if line.startswith("### "):
        return {
            "type": "heading_3",
            "heading_3": {
                "rich_text": [{"type": "text", "text": {"content": line[4:]}}]
            },
        }
    elif line.startswith("## "):
        return {
            "type": "heading_2",
            "heading_2": {
                "rich_text": [{"type": "text", "text": {"content": line[3:]}}]
            },
        }
    elif line.startswith("# "):
        return {
            "type": "heading_1",
            "heading_1": {
                "rich_text": [{"type": "text", "text": {"content": line[2:]}}]
            },
        }
    return None


def _create_list_item_block(line: str) -> dict | None:
    """Create a list item block from markdown list syntax.

    Returns: block dict or None if not a list item
    """
    if line.startswith("- "):
        return {
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"type": "text", "text": {"content": line[2:]}}]
            },
        }
    elif len(line) > 2 and line[0].isdigit() and line[1:3] == ". ":
        return {
            "type": "numbered_list_item",
            "numbered_list_item": {
                "rich_text": [{"type": "text", "text": {"content": line[3:]}}]
            },
        }
    return None


def _create_paragraph_block(line: str) -> dict:
    """Create a paragraph block from text content."""
    if not line.strip():
        # Empty line - create empty paragraph for spacing
        return {"type": "paragraph", "paragraph": {"rich_text": []}}
    else:
        # Regular paragraph with content
        return {
            "type": "paragraph",
            "paragraph": {"rich_text": [{"type": "text", "text": {"content": line}}]},
        }


def markdown_to_blocks(content: str) -> list:
    """Convert markdown content to Notion blocks.

    Handles: headings, code blocks, lists, paragraphs, inline code.
    """
    blocks = []
    lines = content.split("\n")
    i = 0

    while i < len(lines):
        line = lines[i]

        # Code blocks
        if line.strip().startswith("```"):
            block, new_index = _create_code_block(lines, i)
            blocks.append(block)
            i = new_index
            continue

        # Headings
        heading_block = _create_heading_block(line)
        if heading_block:
            blocks.append(heading_block)
            i += 1
            continue

        # List items
        list_block = _create_list_item_block(line)
        if list_block:
            blocks.append(list_block)
            i += 1
            continue

        # Paragraphs (including empty lines)
        blocks.append(_create_paragraph_block(line))
        i += 1

    return blocks


def extract_page_id(url: str) -> str:
    """Extract page ID from Notion URL."""
    # URL format: https://www.notion.so/Page-Title-<id>
    # or https://www.notion.so/<id>
    if not url:
        return ""
    parts = url.rstrip("/").split("-")
    if parts:
        # Last part after final dash, or the whole path segment
        candidate = parts[-1].split("/")[-1]
        # Remove any query params
        candidate = candidate.split("?")[0]
        return candidate
    return ""
