"""The lock that lets runs of auth started together share the logins, so a login one run completes
isn't opened again by another. auth.py imports it from beside itself."""

from __future__ import annotations

import fcntl
import sys
from collections.abc import Generator
from contextlib import AbstractContextManager, contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import IO, assert_never

LOCK_PATH = Path.home() / ".local" / "state" / "auth" / "logins.lock"


@dataclass(frozen=True)
class HeldLoginLock:
    """The permit for a run that holds the login lock. Only entering a LoginLock makes one outside
    the tests."""

    # Whether another run held the lock first, so this run waited for its logins
    waited: bool


@dataclass(frozen=True)
class UnsharedLogins:
    """The permit for a run whose lock couldn't be set up, so it logs in without sharing logins
    with other runs. Losing the lock costs that sharing, and lets this run's Argo CD context reset
    overlap another run's `argocd login`, but never the logins themselves."""


# What lets a run log in: the lock held, or the lock unusable. log_in takes one, so a login can only
# run inside a LoginLock
LoginPermit = HeldLoginLock | UnsharedLogins
LoginLock = AbstractContextManager[LoginPermit]


@dataclass(frozen=True)
class LockedFile:
    handle: IO[str]
    waited: bool


@dataclass(frozen=True)
class CantShare:
    error: OSError


def open_and_lock(path: Path) -> LockedFile | CantShare:
    """Take an exclusive lock on `path`, saying so before waiting on another run's. Any way the lock
    can fail to start, from creating its folder to the file system refusing it, is a CantShare."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        handle = path.open("a")
    except OSError as error:
        return CantShare(error)
    waited = False
    try:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            waited = True
            print(
                "⏳ Another run of auth is logging in; waiting for it...",
                file=sys.stderr,
                flush=True,
            )
            fcntl.flock(handle, fcntl.LOCK_EX)
    except OSError as error:
        handle.close()
        return CantShare(error)
    except BaseException:
        handle.close()
        raise
    return LockedFile(handle, waited)


@contextmanager
def file_login_lock(path: Path) -> Generator[LoginPermit]:
    """An exclusive lock on `path`, which the system releases when the process ends, crashes
    included. Says so before it waits, since a run waiting on another's browser login can take as
    long as that login does. When the lock can't be set up, says why and lets the run log in without
    it."""
    match open_and_lock(path):
        case CantShare(error):
            print(
                f"⚠️  Can't use {path} ({error}), so this run won't share logins with others.",
                file=sys.stderr,
                flush=True,
            )
            yield UnsharedLogins()
        case LockedFile(handle, waited):
            with handle:
                try:
                    yield HeldLoginLock(waited)
                finally:
                    fcntl.flock(handle, fcntl.LOCK_UN)
        case unexpected:
            assert_never(unexpected)
