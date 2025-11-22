"""Git commit types and data structures."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Commit:
    """A git commit with metadata."""

    hash: str  # Short hash (7 chars)
    full_hash: str  # Full SHA
    subject: str  # First line of commit message
    body: str  # Remaining lines of commit message
    date: str  # Relative date (e.g., "2 days ago")
    iso_date: str  # ISO date (YYYY-MM-DD)
    repo: str  # Repository name (owner/repo)
    files: list[str]  # Files changed
    url: str  # GitHub URL
