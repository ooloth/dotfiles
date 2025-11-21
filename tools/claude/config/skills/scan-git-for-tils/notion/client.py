"""Notion API client utilities."""

from __future__ import annotations

from datetime import date

from shared import get_op_secret

from notion.blocks import markdown_to_blocks

# 1Password paths
OP_NOTION_TOKEN = "op://Scripts/Notion/api-access-token"

# Notion database IDs
WRITING_DATA_SOURCE_ID = "c296db5b-d2f1-44d4-abc6-f9a05736b143"
ASSESSED_COMMITS_DATA_SOURCE_ID = "cba80148-aeef-49c9-ba45-5157668b17b3"
NOTION_ASSESSED_COMMITS_DB = "928fcd9e47a84f98824790ac5a6d37ca"


def get_notion_client():
    """Create authenticated Notion client."""
    from notion_client import Client

    token = get_op_secret(OP_NOTION_TOKEN)
    if not token:
        raise Exception("Could not get Notion token from 1Password")
    return Client(auth=token)


def get_assessed_commits_from_notion() -> set[str]:
    """Fetch all assessed commit hashes from Notion database."""
    from notion_client import Client

    token = get_op_secret(OP_NOTION_TOKEN)
    if not token:
        return set()

    try:
        notion = Client(auth=token)
    except Exception:
        return set()

    assessed_hashes = set()
    start_cursor = None

    while True:
        try:
            # Query with pagination
            query_params = {"database_id": NOTION_ASSESSED_COMMITS_DB}
            if start_cursor:
                query_params["start_cursor"] = start_cursor

            response = notion.databases.query(**query_params)

            # Extract commit hashes from results
            for page in response.get("results", []):
                title_prop = page.get("properties", {}).get("Commit Hash", {})
                title_content = title_prop.get("title", [])
                if title_content:
                    commit_hash = title_content[0].get("plain_text", "")
                    if commit_hash:
                        assessed_hashes.add(commit_hash)

            # Check if there are more pages
            if not response.get("has_more", False):
                break

            start_cursor = response.get("next_cursor")

        except Exception:
            break

    return assessed_hashes


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


def find_existing_tracker_entry(notion, commit_hash: str) -> str:
    """Check if tracker entry already exists for this commit. Returns page ID if found."""
    try:
        results = notion.databases.query(
            database_id=ASSESSED_COMMITS_DATA_SOURCE_ID,
            filter={"property": "Commit Hash", "title": {"equals": commit_hash}},
        )
        if results.get("results"):
            return results["results"][0]["id"]
    except Exception:
        pass

    return ""


def update_tracker_entry(notion, page_id: str, writing_page_id: str) -> str:
    """Update existing tracker entry to link to Writing page. Returns page URL."""
    try:
        page = notion.pages.update(
            page_id=page_id,
            properties={
                "Writing": {"relation": [{"id": writing_page_id}]},
                "Assessed": {"date": {"start": date.today().isoformat()}},
            },
        )
        return page.get("url", "")
    except Exception as e:
        raise Exception(f"Failed to update tracker: {e}")


def create_tracker_entry(notion, commit: dict, writing_page_id: str) -> str:
    """Create an entry in TIL Assessed Commits and link to Writing page. Returns page URL."""

    properties = {
        "Commit Hash": {
            "title": [{"type": "text", "text": {"content": commit["hash"]}}]
        },
        "Message": {
            "rich_text": [
                {"type": "text", "text": {"content": commit["message"][:2000]}}
            ]
        },
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
