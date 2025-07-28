# Legacy Directory

This directory will contain the existing dotfiles structure during the migration to feature-based architecture.

## Purpose

During the transition period, this serves as a clear marker for:
- What has been migrated (not here)
- What still needs migration (still here)
- Easy rollback if needed

## Migration Process

Files will be moved from their current locations to:
- `/features/{tool}/` for feature-specific files
- `/core/{utility}/` for cross-cutting concerns

Symlinks will be created from old locations to new ones during the transition to maintain compatibility.

## Temporary

This directory will be removed once the migration is complete and all features have been moved to the new structure.