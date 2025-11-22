"""Pydantic models for validating Notion API responses."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class NotionPageResponse(BaseModel):
    """Validated Notion page response."""

    model_config = ConfigDict(extra="ignore")

    url: str
    id: str
