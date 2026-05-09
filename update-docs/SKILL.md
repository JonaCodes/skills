---
name: update-docs
description: Update docs and feature-index before comitting to github.
disable-model-invocation: true
---

We've just finished making some changes. It's time to ensure our documentation is up to speed. This includes both the `docs` directory. and the `feature-index.yaml` + `feature-details` directory.

If you don't remember what changes we made, you may run `git status` and `git diff` to see what updates we've made. Do not look for the entire branch commit history.

## Guidelines

1. Do not bloat any markdown files
2. The purpose of these files are to onboard future developers and agents - they needs to be lean but still useful
3. The goal of this update is to align the docs to reflect the current state of the code
4. It is possible that no or very minimal changes need to be made, depending on the changes
5. If needed, create new markdown files or index entries. This is true both for separation of concerns, as well as avoiding bloat
