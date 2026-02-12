# Git Branching Strategy

This project follows a structured branching model to ensure stability and smooth development:

- `main`      → **Production**: Only stable, tested code ready for release.
- `dev`       → **Active Development**: Integration branch for features.
- `feature/*` → **Features**: New functionality or major changes.
- `hotfix/*`  → **Production Fixes**: Critical bugs found in the main branch.

## Workflow

1.  Always branch off from `dev` for `feature/*` branches.
2.  Branch off from `main` for `hotfix/*` branches.
3.  Merge `feature/*` back into `dev` after review.
4.  Merge `dev` into `main` for releases.
5.  Merge `hotfix/*` into both `main` and `dev`.
