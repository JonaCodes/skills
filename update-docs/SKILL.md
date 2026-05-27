---
name: update-docs
description: Update docs and feature-index before committing to github.
disable-model-invocation: true
---

We've just finished making changes. Ensure the documentation matches the current code and stays useful for future developers and agents.

Start from `git status` and `git diff`. Do not inspect unrelated branch history.

## Documentation model

This repo has two documentation systems with different purposes:

1. Markdown docs in `docs/`
   - Explain why behavior exists, important gotchas, architectural context, and cross-repo orientation.
   - Keep them lean. They are onboarding/orientation docs, not API references or implementation inventories.
   - Avoid large code snippets, method lists, type dumps, or exhaustive file walkthroughs unless they are essential to understanding a gotcha.

2. Feature map files in `.ai/`
   - `.ai/features-index.yaml` lists distinct features with short names and concise descriptions.
   - `.ai/features-details/<feature>.yaml` points to the main files for that feature.
   - Detail files should list primary starting points, not every related file.
   - A feature should be either a distinct user capability or a distinct automatic app/runtime behavior.

## Update rules

1. Start from `git status` and `git diff`; do not inspect unrelated branch history.
2. Prefer no docs change when the existing docs already cover the behavior.
3. Do not bloat markdown docs to document every implementation detail.
4. If a markdown doc is getting broad, split by concern or route through `docs/index.md`.
5. If feature descriptions are accumulating multiple behaviors, split the feature instead of writing a mega-feature.
6. Keep `docs/index.md` as a router: short “if working on X, read Y” entries only.

## Verification

- markdown links resolve
- every feature-index entry has a matching detail file
- no orphaned feature detail files remain
- listed feature detail paths exist
