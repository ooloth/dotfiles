"""Notion assessed commits tracking utilities."""

from __future__ import annotations

from datetime import date

from notion_client import Client

from notion.validation import (
    AssessedCommitPage,
    CommitInput,
    NotionPageResponse,
    NotionQueryResponse,
)
from op.secrets import OP_NOTION_TOKEN_PATH, get_op_secret

# Notion database IDs
ASSESSED_COMMITS_DATA_SOURCE_ID = "cba80148-aeef-49c9-ba45-5157668b17b3"
NOTION_ASSESSED_COMMITS_DB = "928fcd9e47a84f98824790ac5a6d37ca"


def get_assessed_commits_from_notion() -> set[str]:
    """Fetch all assessed commit hashes from Notion database."""
    from notion_client.helpers import collect_paginated_api

    try:
        token = get_op_secret(OP_NOTION_TOKEN_PATH)
        notion = Client(auth=token)
    except Exception:
        return set()

    try:
        # Use helper to automatically handle pagination (Notion API v2025-09-03)
        raw_pages = collect_paginated_api(
            notion.data_sources.query,
            data_source_id=ASSESSED_COMMITS_DATA_SOURCE_ID,
        )

        # Extract commit hashes from results
        assessed_hashes = set()
        for raw_page in raw_pages:
            # Validate page structure and extract commit hash
            page = AssessedCommitPage.model_validate(raw_page)
            commit_hash = page.properties.commit_hash.text
            if commit_hash:
                assessed_hashes.add(commit_hash)

        return assessed_hashes

    except Exception:
        return set()


def find_existing_tracker_entry(notion: Client, commit_hash: str) -> str:
    """Check if tracker entry already exists for this commit. Returns page ID if found."""
    try:
        raw_response = notion.data_sources.query(
            data_source_id=ASSESSED_COMMITS_DATA_SOURCE_ID,
            filter={"property": "Commit Hash", "title": {"equals": commit_hash}},
        )
        # Validate response immediately
        response = NotionQueryResponse.model_validate(raw_response)
        if response.results:
            # Access validated page ID via dot notation
            return response.results[0].id
    except Exception:
        pass

    return ""


def update_tracker_entry(notion: Client, page_id: str, writing_page_id: str) -> str:
    """Update existing tracker entry to link to Writing page. Returns page URL."""
    try:
        response = notion.pages.update(
            page_id=page_id,
            properties={
                "Writing": {"relation": [{"id": writing_page_id}]},
                "Assessed": {"date": {"start": date.today().isoformat()}},
            },
        )
        # Parse response immediately to validate structure
        page = NotionPageResponse.model_validate(response)
        return page.url
    except Exception as e:
        raise Exception(f"Failed to update tracker: {e}")


def create_tracker_entry(notion: Client, commit: CommitInput, writing_page_id: str) -> str:
    """Create an entry in TIL Assessed Commits and link to Writing page. Returns page URL."""

    properties = {
        "Commit Hash": {"title": [{"type": "text", "text": {"content": commit.hash}}]},
        "Message": {"rich_text": [{"type": "text", "text": {"content": commit.message[:2000]}}]},
        "Repo": {"rich_text": [{"type": "text", "text": {"content": commit.repo}}]},
        "Assessed": {"date": {"start": date.today().isoformat()}},
        "Writing": {"relation": [{"id": writing_page_id}]},
    }

    # Only add Commit Date if present (None breaks Notion API)
    if commit.date:
        properties["Commit Date"] = {"date": {"start": commit.date}}

    response = notion.pages.create(
        parent={"data_source_id": ASSESSED_COMMITS_DATA_SOURCE_ID},
        properties=properties,
    )

    # Parse response immediately to validate structure
    page = NotionPageResponse.model_validate(response)
    return page.url
