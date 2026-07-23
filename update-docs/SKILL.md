---
name: update-docs
description: Update the existing documentation for this repository following code changes. Only run this once the task is complete and functional.
disable-model-invocation: true
---

We have just finished making some changes in this repository. Your task is to review the existing documentation in `docs/` and update it to reflect the changes in the code.

Start by reviewing the local changes in this repo, then read `docs/index.md` to orient yourself on the doc files.

**Note:** it is possible that no documentation updates are necessary if the changes are minor. This is fine, just inform the user about it.

## Creating and Updating Docs:

- All documentation should live in a `docs/` directory at the project root.
- Keep `index.md` updated.
- Create subdirectories under `docs/` as needed to organize the documentation.
- Each file inside of `docs/` and its subdirectories should be a lean markdown file that focuses on a feature, a flow, or an architectural pattern.

**Important Guidelines:**

- Each documentation file should include two sections:
  - Main section: overview of the feature/flow/architectural pattern, how it works, why it exists, important 'gotchas', etc. This should be written as if onboarding a new employee.
  - References section: list of files that are relevant to the feature/flow/architectural pattern. This acts as a pointer to the actual code files. These reference files should point to meaningful starting points/main logic areas; avoid helper/util/test files.
- Documentation files should avoid code snippets and exhaustive walkthroughs unless they are essential to understanding a gotcha or crucial behavior.
- Each file should aim to be under 320 lines. Split larger files into meaningful subfiles under a shared subdirectory when necessary.
- The main rule for documentation files is: keep it lean but meaningful, so it is easy to onboard new employees and coding agents.

## Documentation Maintenance and Hygiene Guidelines:

- If an existing documentation file or directory is no longer relevant (i.e a feature has been removed or refactored beyond recognition), delete it and remove any references to it from other documentation files (including from `docs/index.md`).
- When deleting entire documentation files/subdirectories, let the user know with a short reason.
- Do not document callbacks or references to old, non-existant code. The docs should be current-status snapshots, not archive logs of what used to be.
- Do not bloat documentation files just for the sake of adding docs.
- After adding new documentation, run a short keyword scan against existing docs to ensure you haven't accidentally duplicated docs.
