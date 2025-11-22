#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["notion-client", "pydantic"]
# ///
"""
Publish a TIL draft to Notion and update the tracker.

Usage:
    echo '<json>' | uv run publish_til.py

Input (JSON via stdin):
    {
        "title": "TIL Title",
        "content": "Markdown content",
        "slug": "til-slug",
        "description": "One-line summary",
        "commit": {
            "hash": "full-sha-hash",
            "message": "commit message",
            "repo": "owner/repo",
            "date": "2025-01-15"
        }
    }

Output (JSON):
    {
        "writing_url": "https://notion.so/...",
        "tracker_url": "https://notion.so/..."
    }

Requires:
    - op CLI installed and authenticated (1Password)
    - uv (for dependency management)
"""

from __future__ import annotations

import json
import sys
from dataclasses import asdict, dataclass

from pydantic import BaseModel, Field, ValidationError

from notion.blocks import extract_page_id
from notion.client import get_notion_client
from notion.commits import (
    create_tracker_entry,
    find_existing_tracker_entry,
    update_tracker_entry,
)
from notion.validation import CommitInput
from notion.writing import create_writing_page


class PublishTilInput(BaseModel):
    """Input for publishing a TIL to Notion."""

    title: str = Field(..., min_length=1, max_length=2000)
    content: str = Field(..., min_length=1)
    slug: str = Field(..., min_length=1)
    description: str = Field(..., min_length=1, max_length=2000)
    commit: CommitInput


@dataclass
class PublishTilOutput:
    """Output from publishing a TIL to Notion."""

    writing_url: str
    tracker_url: str


def main() -> None:
    # Read and validate JSON input from stdin
    try:
        raw_input = json.loads(sys.stdin.read())
        input_data = PublishTilInput.model_validate(raw_input)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {e}"}))
        sys.exit(1)
    except ValidationError as e:
        print(json.dumps({"error": f"Validation error: {e}"}))
        sys.exit(1)

    try:
        # Create Notion client
        notion = get_notion_client()

        # Create Writing page
        writing_url = create_writing_page(
            notion,
            input_data.title,
            input_data.content,
            input_data.slug,
            input_data.description,
        )

        if not writing_url:
            print(json.dumps({"error": "Failed to create Writing page"}))
            sys.exit(1)

        # Extract page ID for relation
        writing_page_id = extract_page_id(writing_url)

        # Check if tracker entry already exists
        existing_tracker_id = find_existing_tracker_entry(notion, input_data.commit.hash)

        if existing_tracker_id:
            # Update existing entry with Writing relation
            tracker_url = update_tracker_entry(notion, existing_tracker_id, writing_page_id)
        else:
            # Create new tracker entry with relation to Writing page
            tracker_url = create_tracker_entry(notion, input_data.commit, writing_page_id)

        # Output results as dataclass
        output = PublishTilOutput(
            writing_url=writing_url,
            tracker_url=tracker_url,
        )
        print(json.dumps(asdict(output), indent=2))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
