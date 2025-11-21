"""Notion block conversion utilities."""

from __future__ import annotations


def markdown_to_blocks(content: str) -> list:
    """Convert markdown content to Notion blocks.

    Handles: headings, code blocks, lists, paragraphs, inline code.
    """
    blocks = []
    lines = content.split("\n")
    i = 0

    while i < len(lines):
        line = lines[i]

        # Code blocks - handle language parameter properly
        if line.strip().startswith("```"):
            language = line.strip()[3:].strip()
            # Map common language names to Notion's expected values
            lang_map = {
                "": "plain text",
                "js": "javascript",
                "ts": "typescript",
                "py": "python",
                "sh": "shell",
                "bash": "shell",
                "zsh": "shell",
            }
            language = lang_map.get(language, language) or "plain text"

            code_lines = []
            i += 1
            # Collect all lines until closing ```
            while i < len(lines):
                if lines[i].strip().startswith("```"):
                    break
                code_lines.append(lines[i])
                i += 1

            # Create code block with proper content
            code_content = "\n".join(code_lines)
            if code_content or True:  # Always create block even if empty
                blocks.append({
                    "type": "code",
                    "code": {
                        "rich_text": [{"type": "text", "text": {"content": code_content}}],
                        "language": language,
                    }
                })
            i += 1
            continue

        # Headings
        if line.startswith("### "):
            blocks.append({
                "type": "heading_3",
                "heading_3": {"rich_text": [{"type": "text", "text": {"content": line[4:]}}]}
            })
        elif line.startswith("## "):
            blocks.append({
                "type": "heading_2",
                "heading_2": {"rich_text": [{"type": "text", "text": {"content": line[3:]}}]}
            })
        elif line.startswith("# "):
            blocks.append({
                "type": "heading_1",
                "heading_1": {"rich_text": [{"type": "text", "text": {"content": line[2:]}}]}
            })
        # Bullet lists
        elif line.startswith("- "):
            blocks.append({
                "type": "bulleted_list_item",
                "bulleted_list_item": {"rich_text": [{"type": "text", "text": {"content": line[2:]}}]}
            })
        # Numbered lists
        elif len(line) > 2 and line[0].isdigit() and line[1:3] == ". ":
            blocks.append({
                "type": "numbered_list_item",
                "numbered_list_item": {"rich_text": [{"type": "text", "text": {"content": line[3:]}}]}
            })
        # Empty lines - create empty paragraph for spacing
        elif not line.strip():
            blocks.append({
                "type": "paragraph",
                "paragraph": {"rich_text": []}
            })
        # Regular paragraphs
        else:
            blocks.append({
                "type": "paragraph",
                "paragraph": {"rich_text": [{"type": "text", "text": {"content": line}}]}
            })

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
