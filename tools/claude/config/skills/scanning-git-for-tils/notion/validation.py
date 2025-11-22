"""Pydantic models for validating Notion API requests and responses."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class CommitInput(BaseModel):
    """Commit metadata for creating tracker entries."""

    hash: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)
    repo: str = Field(..., min_length=1)
    date: str | None = None


class NotionRichText(BaseModel):
    """Rich text content in Notion."""

    model_config = ConfigDict(extra="ignore")

    plain_text: str


class NotionTitleProperty(BaseModel):
    """Title property structure in Notion."""

    model_config = ConfigDict(extra="ignore")

    title: list[NotionRichText]

    @property
    def text(self) -> str:
        """Extract first title text or empty string."""
        return self.title[0].plain_text if self.title else ""


class AssessedCommitProperties(BaseModel):
    """Properties for TIL Assessed Commits database pages."""

    model_config = ConfigDict(extra="ignore")

    commit_hash: NotionTitleProperty = Field(alias="Commit Hash")


class AssessedCommitPage(BaseModel):
    """Page from TIL Assessed Commits database."""

    model_config = ConfigDict(extra="ignore")

    id: str
    url: str
    properties: AssessedCommitProperties


class NotionPageResponse(BaseModel):
    """Validated Notion page response (create/update)."""

    model_config = ConfigDict(extra="ignore")

    url: str
    id: str


class NotionQueryResponse(BaseModel):
    """Validated Notion query response for assessed commits."""

    model_config = ConfigDict(extra="ignore")

    results: list[AssessedCommitPage]
