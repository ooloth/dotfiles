"""Notion Writing database utilities."""

from __future__ import annotations

from notion.blocks import markdown_to_blocks

# Notion database IDs
WRITING_DATA_SOURCE_ID = "c296db5b-d2f1-44d4-abc6-f9a05736b143"


def create_writing_page(
    notion, title: str, content: str, slug: str, description: str
) -> str:
    """Create a TIL draft in the Writing database. Returns page URL."""

    page = notion.pages.create(
        parent={"database_id": WRITING_DATA_SOURCE_ID},
        properties={
            "Title": {"title": [{"type": "text", "text": {"content": title}}]},
            "Status": {"status": {"name": "Claude Draft"}},
            "Type": {"select": {"name": "how-to"}},
            "Destination": {"multi_select": [{"name": "blog"}]},
            "Description": {
                "rich_text": [{"type": "text", "text": {"content": description}}]
            },
            "Slug": {"rich_text": [{"type": "text", "text": {"content": slug}}]},
        },
        children=markdown_to_blocks(content),
    )

    return page.get("url", "")
