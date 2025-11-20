#!/usr/bin/env python3
"""
Publish a TIL draft to Notion and update the tracker.

Usage:
    echo '<json>' | python3 publish_til.py

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
"""

import sys
import json
import urllib.request
import urllib.error
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


def notion_request(token: str, endpoint: str, body: dict) -> dict:
    """Make a request to the Notion API."""
    url = f"https://api.notion.com/v1/{endpoint}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Notion-Version": "2022-06-28",
        "Content-Type": "application/json",
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers=headers,
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        raise Exception(f"Notion API error: {e.code} - {error_body}")


def create_writing_page(token: str, title: str, content: str, slug: str, description: str) -> str:
    """Create a TIL draft in the Writing database. Returns page URL."""

    # Build rich text for title
    title_rich_text = [{"type": "text", "text": {"content": title}}]

    body = {
        "parent": {"database_id": WRITING_DATA_SOURCE_ID},
        "properties": {
            "Title": {"title": title_rich_text},
            "Status": {"status": {"name": "Claude Draft"}},
            "Type": {"select": {"name": "how-to"}},
            "Destination": {"multi_select": [{"name": "blog"}]},
            "Description": {"rich_text": [{"type": "text", "text": {"content": description}}]},
            "Slug": {"rich_text": [{"type": "text", "text": {"content": slug}}]},
        },
        "children": markdown_to_blocks(content),
    }

    result = notion_request(token, "pages", body)
    return result.get("url", "")


def create_tracker_entry(token: str, commit: dict, writing_page_id: str) -> str:
    """Create an entry in TIL Assessed Commits and link to Writing page. Returns page URL."""

    body = {
        "parent": {"database_id": ASSESSED_COMMITS_DATA_SOURCE_ID},
        "properties": {
            "Commit Hash": {"title": [{"type": "text", "text": {"content": commit["hash"]}}]},
            "Message": {"rich_text": [{"type": "text", "text": {"content": commit["message"][:2000]}}]},
            "Repo": {"rich_text": [{"type": "text", "text": {"content": commit["repo"]}}]},
            "Commit Date": {"date": {"start": commit["date"]} if commit.get("date") else None},
            "Assessed": {"date": {"start": date.today().isoformat()}},
            "Writing": {"relation": [{"id": writing_page_id}]},
        },
    }

    result = notion_request(token, "pages", body)
    return result.get("url", "")


def markdown_to_blocks(content: str) -> list:
    """Convert markdown content to Notion blocks.

    This is a simplified converter that handles common patterns.
    For complex content, Notion's API will do additional parsing.
    """
    blocks = []
    lines = content.split("\n")
    i = 0

    while i < len(lines):
        line = lines[i]

        # Code blocks
        if line.startswith("```"):
            language = line[3:].strip() or "plain text"
            code_lines = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code_lines.append(lines[i])
                i += 1
            blocks.append({
                "type": "code",
                "code": {
                    "rich_text": [{"type": "text", "text": {"content": "\n".join(code_lines)}}],
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
        elif len(line) > 2 and line[0].isdigit() and line[1] == "." and line[2] == " ":
            blocks.append({
                "type": "numbered_list_item",
                "numbered_list_item": {"rich_text": [{"type": "text", "text": {"content": line[3:]}}]}
            })
        # Empty lines (skip)
        elif not line.strip():
            pass
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

    commit = input_data["commit"]
    commit_required = ["hash", "message", "repo"]
    commit_missing = [f for f in commit_required if f not in commit]
    if commit_missing:
        print(json.dumps({"error": f"Missing commit fields: {commit_missing}"}))
        sys.exit(1)

    # Get Notion token
    token = get_op_secret(OP_NOTION_TOKEN)
    if not token:
        print(json.dumps({"error": "Could not get Notion token from 1Password"}))
        sys.exit(1)

    try:
        # Create Writing page
        writing_url = create_writing_page(
            token,
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

        # Create tracker entry with relation to Writing page
        tracker_url = create_tracker_entry(token, commit, writing_page_id)

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
