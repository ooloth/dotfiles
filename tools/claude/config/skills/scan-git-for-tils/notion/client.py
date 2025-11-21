"""Notion API client utilities."""

from __future__ import annotations

from op.secrets import get_op_secret, OP_NOTION_TOKEN


def get_notion_client():
    """Create authenticated Notion client."""
    from notion_client import Client

    token = get_op_secret(OP_NOTION_TOKEN)
    if not token:
        raise Exception("Could not get Notion token from 1Password")
    return Client(auth=token)
