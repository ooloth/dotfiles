"""The lock that lets runs of auth started together share the logins, so a login one run completes
isn't opened again by another. auth.py imports it from beside itself."""

from __future__ import annotations

import fcntl
import sys
from collections.abc import Generator
from contextlib import AbstractContextManager, contextmanager
from dataclasses import dataclass
from pathlib import Path

LOCK_PATH = Path.home() / ".local" / "state" / "auth" / "logins.lock"


@dataclass(frozen=True)
class HeldLoginLock:
    """Marks that this run holds the login lock. Only entering a LoginLock makes one outside the
    tests, and log_in takes it so a call outside the lock reads as wrong."""


@dataclass(frozen=True)
class UnsharedLogins:
    """The lock couldn't be set up, so this run logs in without sharing logins with other runs. The
    lock only stops two runs opening the same login, so losing it costs that and not the logins."""

    reason: str


# What lets a run log in: the lock held, or the lock unusable
LoginPermit = HeldLoginLock | UnsharedLogins
LoginLock = AbstractContextManager[LoginPermit]


@contextmanager
def file_login_lock(path: Path) -> Generator[LoginPermit]:
    """An exclusive lock on `path`, which the system releases when the process ends, crashes
    included. Says so before it waits, since a run waiting on another's browser login can take as
    long as that login does."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        handle = path.open("a")
    except OSError as error:
        print(
            f"⚠️  Can't use {path} ({error}), so this run won't share logins with others.",
            file=sys.stderr,
            flush=True,
        )
        yield UnsharedLogins(str(error))
        return
    with handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print(
                "⏳ Another run of auth is logging in; waiting for it...",
                file=sys.stderr,
                flush=True,
            )
            fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield HeldLoginLock()
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)
