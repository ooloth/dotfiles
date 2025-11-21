"""1Password secret retrieval utilities."""

from __future__ import annotations

import subprocess

# 1Password paths
OP_NOTION_TOKEN = "op://Scripts/Notion/api-access-token"


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
