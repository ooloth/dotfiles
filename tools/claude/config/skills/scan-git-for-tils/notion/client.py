"""Notion API client utilities."""

from __future__ import annotations

from op.secrets import OP_NOTION_TOKEN_PATH, get_op_secret


def get_notion_client():
    """Create authenticated Notion client.

    Raises:
        RuntimeError: If 1Password secret retrieval fails.
    """
    from notion_client import Client

    token = get_op_secret(OP_NOTION_TOKEN_PATH)
    return Client(auth=token)
