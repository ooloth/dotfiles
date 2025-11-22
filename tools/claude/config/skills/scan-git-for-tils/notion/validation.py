"""Pydantic models for validating Notion API responses."""

from __future__ import annotations

from pydantic import BaseModel


class NotionPageResponse(BaseModel):
    """Validated Notion page response."""

    url: str
    id: str

    class Config:
        # Allow extra fields from Notion API
        extra = "ignore"


class NotionQueryResponse(BaseModel):
    """Validated Notion database query response."""

    results: list[dict]
    has_more: bool
    next_cursor: str | None = None

    class Config:
        extra = "ignore"
