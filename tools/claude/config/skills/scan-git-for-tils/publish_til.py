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

from __future__ import annotations

import sys
import json
import subprocess
from datetime import date

# 1Password paths
OP_NOTION_TOKEN = "op://Scripts/Notion/api-access-token"

# Notion database IDs
WRITING_DATA_SOURCE_ID = "c296db5b-d2f1-44d4-abc6-f9a05736b143"
ASSESSED_COMMITS_DATA_SOURCE_ID = "cba80148-aeef-49c9-ba45-5157668b17b3"


def get_op_secret(path: str) -> str:
    """Fetch a secret from 1Password."""
    result = subprocess.run(
        ["op", "read", path],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def get_notion_client() -> Client:
    """Create authenticated Notion client."""
    from notion_client import Client

    token = get_op_secret(OP_NOTION_TOKEN)
    if not token:
        raise Exception("Could not get Notion token from 1Password")
    return Client(auth=token)


def create_writing_page(notion: Client, title: str, content: str, slug: str, description: str) -> str:
    """Create a TIL draft in the Writing database. Returns page URL."""

    page = notion.pages.create(
        parent={"database_id": WRITING_DATA_SOURCE_ID},
        properties={
            "Title": {"title": [{"type": "text", "text": {"content": title}}]},
            "Status": {"status": {"name": "Claude Draft"}},
            "Type": {"select": {"name": "how-to"}},
            "Destination": {"multi_select": [{"name": "blog"}]},
            "Description": {"rich_text": [{"type": "text", "text": {"content": description}}]},
            "Slug": {"rich_text": [{"type": "text", "text": {"content": slug}}]},
        },
        children=markdown_to_blocks(content),
    )

    return page.get("url", "")


def find_existing_tracker_entry(notion: Client, commit_hash: str) -> str:
    """Check if tracker entry already exists for this commit. Returns page ID if found."""
    try:
        results = notion.databases.query(
            database_id=ASSESSED_COMMITS_DATA_SOURCE_ID,
            filter={
                "property": "Commit Hash",
                "title": {
                    "equals": commit_hash
                }
            }
        )
        if results.get("results"):
            return results["results"][0]["id"]
    except Exception:
        pass

    return ""


def update_tracker_entry(notion: Client, page_id: str, writing_page_id: str) -> str:
    """Update existing tracker entry to link to Writing page. Returns page URL."""
    try:
        page = notion.pages.update(
            page_id=page_id,
            properties={
                "Writing": {"relation": [{"id": writing_page_id}]},
                "Assessed": {"date": {"start": date.today().isoformat()}},
            }
        )
        return page.get("url", "")
    except Exception as e:
        raise Exception(f"Failed to update tracker: {e}")


def create_tracker_entry(notion: Client, commit: dict, writing_page_id: str) -> str:
    """Create an entry in TIL Assessed Commits and link to Writing page. Returns page URL."""

    properties = {
        "Commit Hash": {"title": [{"type": "text", "text": {"content": commit["hash"]}}]},
        "Message": {"rich_text": [{"type": "text", "text": {"content": commit["message"][:2000]}}]},
        "Repo": {"rich_text": [{"type": "text", "text": {"content": commit["repo"]}}]},
        "Assessed": {"date": {"start": date.today().isoformat()}},
        "Writing": {"relation": [{"id": writing_page_id}]},
    }

    # Only add Commit Date if present (None breaks Notion API)
    if commit.get("date"):
        properties["Commit Date"] = {"date": {"start": commit["date"]}}

    page = notion.pages.create(
        parent={"database_id": ASSESSED_COMMITS_DATA_SOURCE_ID},
        properties=properties,
    )

    return page.get("url", "")


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
