"""Shared utilities for TIL workflow."""

from __future__ import annotations

import subprocess


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
