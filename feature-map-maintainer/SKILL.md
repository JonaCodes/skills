---
name: feature-map-maintainer
description: Maintain `.ai/feature-map.yaml` directly from staged git changes. Use when checking whether the current commit makes the map stale and updating only the affected map entries.
disable-model-invocation: true
---

# Feature Map Maintainer

Use this skill to keep `.ai/feature-map.yaml` current from staged git changes. Treat the map as the working source of truth for feature-oriented code navigation.

Read the current map and the staged git diff, then decide whether the map needs to change. Update only the affected entries unless the staged changes clearly introduce a genuinely new feature area, in which case add a new top-level map entry.

The `scripts/` paths in this skill are bundled with the skill itself, not with the target repository. Run them from the skill directory, or otherwise use the bundled script path with `--repo-root <target-repo>`.

## Workflow

1. Read `<target-repo>/.ai/feature-map.yaml`. If it does not exist, stop and explain that the map must exist before maintenance can run.
2. Read `git diff --cached --name-only` and `git diff --cached` from `<target-repo>`.
3. If there are no staged changes, say no map update is needed and stop.
4. Match staged changes against the existing map entries first.
5. For affected entries, update `description`, `core_files`, and `supporting_files` only when the staged diff shows the map has become stale.
6. Keep `core_files` focused on the feature's primary implementation locus.
7. Use `supporting_files` for adjacent high-signal context such as app shells, bridge/protocol boundaries, shared contracts, config/state surfaces, service entrypoints, or one useful test.
8. Use repo search and the bundled `scripts/trace_flow.py --repo-root <target-repo> <file>` only when you need deterministic expansion from a changed file into related implementation surfaces.
9. If the staged changes clearly introduce a genuinely new feature area that is not represented in the map, add a new top-level map entry directly to `.ai/feature-map.yaml` using the same `core_files` / `supporting_files` shape.
10. Keep both file lists lean and high-signal. If either list must exceed 5 files to remain accurate, keep the extra files but emit a yellow warning line in the output: `Warning: feature list exceeds 5 files`.

## Rules

- Use staged changes only. Do not mix unstaged work into maintenance decisions.
- Patch the smallest relevant section of the map.
- Do not churn descriptions or reorder file lists unless the diff makes that necessary.
- Do not document every touched file. Keep the map useful for navigation.
- A new top-level entry is allowed when the staged diff clearly creates a new feature area.
- `supporting_files` is optional. Omit it when there is no meaningful supporting context.
- If a file is central to the feature, put it in `core_files`; do not hide primary behavior in `supporting_files`.
- If either list exceeds 5 files, warn and continue rather than dropping important files.
