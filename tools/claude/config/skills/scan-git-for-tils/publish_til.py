#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["notion-client"]
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

import sys
import json

from notion.client import (
    get_notion_client,
    create_writing_page,
    find_existing_tracker_entry,
    update_tracker_entry,
    create_tracker_entry,
)
from notion.blocks import extract_page_id


def main():
    # Read JSON input from stdin
    try:
        input_data = json.loads(sys.stdin.read())
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON input: {e}"}))
        sys.exit(1)

    # Validate required fields
    required = ["title", "content", "slug", "description", "commit"]
    missing = [f for f in required if f not in input_data]
    if missing:
        print(json.dumps({"error": f"Missing required fields: {missing}"}))
        sys.exit(1)

    # Validate field lengths (Notion API limits)
    if len(input_data["title"]) > 2000:
        print(json.dumps({"error": "Title exceeds 2000 characters"}))
        sys.exit(1)
    if len(input_data["description"]) > 2000:
        print(json.dumps({"error": "Description exceeds 2000 characters"}))
        sys.exit(1)

    commit = input_data["commit"]
    commit_required = ["hash", "message", "repo"]
    commit_missing = [f for f in commit_required if f not in commit]
    if commit_missing:
        print(json.dumps({"error": f"Missing commit fields: {commit_missing}"}))
        sys.exit(1)

    try:
        # Create Notion client
        notion = get_notion_client()

        # Create Writing page
        writing_url = create_writing_page(
            notion,
            input_data["title"],
            input_data["content"],
            input_data["slug"],
            input_data["description"],
        )

        if not writing_url:
            print(json.dumps({"error": "Failed to create Writing page"}))
            sys.exit(1)

        # Extract page ID for relation
        writing_page_id = extract_page_id(writing_url)

        # Check if tracker entry already exists
        existing_tracker_id = find_existing_tracker_entry(notion, commit["hash"])

        if existing_tracker_id:
            # Update existing entry with Writing relation
            tracker_url = update_tracker_entry(notion, existing_tracker_id, writing_page_id)
        else:
            # Create new tracker entry with relation to Writing page
            tracker_url = create_tracker_entry(notion, commit, writing_page_id)

        # Output results
        print(json.dumps({
            "writing_url": writing_url,
            "tracker_url": tracker_url,
        }, indent=2))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
