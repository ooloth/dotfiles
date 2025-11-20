#!/usr/bin/env python3
"""
Example skill demonstrating MCP code execution best practices.

This template shows:
1. Type hints for clarity and reliability
2. Data filtering in code before returning to Claude
3. Caching patterns to avoid redundant operations
4. Error handling with user-friendly messages
5. Security-conscious data handling
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


# =============================================================================
# CONFIGURATION
# =============================================================================

CACHE_DIR = Path.home() / ".claude" / ".cache"
CACHE_FILE = CACHE_DIR / "skill-name.json"
CACHE_TTL_SECONDS = 3600  # 1 hour

# Security: Never include these in output
SENSITIVE_KEYS = {"password", "token", "secret", "key", "api_key"}


# =============================================================================
# TYPE DEFINITIONS
# =============================================================================

class ProcessedResult:
    """Typed interface for processed results."""

    def __init__(
        self,
        summary: str,
        items: List[Dict[str, Any]],
        metadata: Dict[str, Any]
    ):
        self.summary = summary
        self.items = items
        self.metadata = metadata

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "summary": self.summary,
            "items": self.items,
            "metadata": self.metadata,
        }


# =============================================================================
# CACHING UTILITIES
# =============================================================================

def ensure_cache_dir() -> None:
    """Ensure cache directory exists."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def load_cache() -> Optional[Dict[str, Any]]:
    """
    Load cached data if it exists and is still valid.

    Returns:
        Cached data if valid, None otherwise
    """
    if not CACHE_FILE.exists():
        return None

    try:
        with open(CACHE_FILE, 'r') as f:
            cache = json.load(f)

        # Check if cache is still valid
        cached_at = datetime.fromisoformat(cache.get("cached_at", ""))
        age_seconds = (datetime.now(timezone.utc) - cached_at).total_seconds()

        if age_seconds < CACHE_TTL_SECONDS:
            return cache.get("data")

        return None
    except (json.JSONDecodeError, ValueError, KeyError):
        # Cache corrupted or invalid, ignore it
        return None


def save_cache(data: Any) -> None:
    """
    Save data to cache with timestamp.

    Args:
        data: Data to cache (must be JSON serializable)
    """
    ensure_cache_dir()

    cache = {
        "cached_at": datetime.now(timezone.utc).isoformat(),
        "data": data,
    }

    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)


# =============================================================================
# DATA PROCESSING - This is where token efficiency happens
# =============================================================================

def fetch_raw_data() -> List[Dict[str, Any]]:
    """
    Fetch raw data from source.

    This could be:
    - API call (subprocess.run(['curl', ...]))
    - File read (Path.read_text())
    - Command output (subprocess.run(['command', ...]))

    Returns:
        Raw data (potentially large and unfiltered)
    """
    # Example: simulated raw data
    # In a real skill, this would call an API, run a command, etc.
    return [
        {"id": 1, "name": "Item 1", "status": "active", "internal_key": "secret123"},
        {"id": 2, "name": "Item 2", "status": "inactive", "internal_key": "secret456"},
        {"id": 3, "name": "Item 3", "status": "active", "internal_key": "secret789"},
    ]


def sanitize_sensitive_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Remove sensitive keys from data before returning to Claude.

    This implements "deterministic security rules for data flow" from the article.

    Args:
        data: Dictionary potentially containing sensitive data

    Returns:
        Sanitized dictionary with sensitive keys removed
    """
    return {
        k: v for k, v in data.items()
        if k.lower() not in SENSITIVE_KEYS
    }


def filter_and_process(raw_data: List[Dict[str, Any]]) -> ProcessedResult:
    """
    Filter and process raw data in code (not in Claude).

    This is the key to token efficiency:
    - Raw data might be thousands of tokens
    - Filtered/summarized data might be hundreds of tokens
    - ~90%+ token reduction

    Args:
        raw_data: Unfiltered data from source

    Returns:
        Processed result with only essential information
    """
    # Filter: only active items
    active_items = [item for item in raw_data if item.get("status") == "active"]

    # Sanitize: remove sensitive data
    safe_items = [sanitize_sensitive_data(item) for item in active_items]

    # Transform: extract only what Claude needs to know
    items = [
        {
            "id": item["id"],
            "name": item["name"],
            "status": item["status"],
        }
        for item in safe_items
    ]

    # Calculate summary
    summary = f"Found {len(items)} active items out of {len(raw_data)} total"

    # Metadata
    metadata = {
        "total_count": len(raw_data),
        "active_count": len(items),
        "processed_at": datetime.now(timezone.utc).isoformat(),
    }

    return ProcessedResult(summary, items, metadata)


# =============================================================================
# OUTPUT FORMATTING
# =============================================================================

def format_markdown(result: ProcessedResult) -> str:
    """
    Format result as markdown for Claude to display.

    Args:
        result: Processed result

    Returns:
        Markdown-formatted string
    """
    lines = [
        f"# {result.summary}",
        "",
        "## Items",
        "",
    ]

    for item in result.items:
        lines.append(f"- **{item['name']}** (ID: {item['id']}) - {item['status']}")

    lines.extend([
        "",
        "## Metadata",
        "",
        f"- Total items processed: {result.metadata['total_count']}",
        f"- Active items: {result.metadata['active_count']}",
        f"- Processed at: {result.metadata['processed_at']}",
    ])

    return "\n".join(lines)


def format_json(result: ProcessedResult) -> str:
    """
    Format result as JSON for programmatic use.

    Args:
        result: Processed result

    Returns:
        JSON-formatted string
    """
    return json.dumps(result.to_dict(), indent=2)


# =============================================================================
# MAIN EXECUTION
# =============================================================================

def main() -> int:
    """
    Main execution function.

    Returns:
        Exit code (0 for success, 1 for error)
    """
    try:
        # Check for cached data first
        cached_data = load_cache()
        if cached_data is not None:
            # Use cached data (token efficiency via caching)
            result = ProcessedResult(
                cached_data["summary"],
                cached_data["items"],
                cached_data["metadata"],
            )
            print("(Using cached data)", file=sys.stderr)
        else:
            # Fetch and process new data
            raw_data = fetch_raw_data()
            result = filter_and_process(raw_data)

            # Cache the processed result (not raw data!)
            save_cache(result.to_dict())

        # Format output based on optional argument
        output_format = sys.argv[1] if len(sys.argv) > 1 else "markdown"

        if output_format == "json":
            print(format_json(result))
        else:
            print(format_markdown(result))

        return 0

    except Exception as e:
        # User-friendly error message
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
