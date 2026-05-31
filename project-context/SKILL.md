---
name: project-context
description: Get the relevant context of the project before diving into planning/implementation
disable-model-invocation: true
---

For starters, read the root `README.md` for general context, and the root `CLAUDE.md` as well. Based on the request, find the relevant docs to read by reading `docs/index.md` and branching out from there.

For more detailed exploration, only if the repo has a `.ai/` directory at its root, read the `.ai/features-index.yaml` file to discern which actual code files are relevant, then go to the matching `.ai/features-details/`.

If there is no `.ai/` directory, the docs themselves should have similar file pointers you can dive into.
