---
name: map-guided-explorer
description: Start coding exploration from the maintained `.ai/feature-map.yaml` instead of broad repo wandering. Use when implementing or investigating a mapped feature in a large repo and you want bounded, map-first navigation with deterministic tracing only when the initial file lists are insufficient.
disable-model-invocation: true
---

# Map Guided Explorer

Treat `.ai/feature-map.yaml` as the working source of truth for feature-oriented code navigation.

Each map entry separates `core_files` from `supporting_files`:

- `core_files` are the primary implementation files for the feature
- `supporting_files` are adjacent high-signal files that help explain or safely modify the feature

The `scripts/` paths in this skill are bundled with the skill itself, not with the target repository. Run them from the skill directory, or otherwise use the bundled script path with `--repo-root <target-repo>`.

## Workflow

1. Read `.ai/feature-map.yaml` before broad searching.
2. If the map does not exist, tell the user to run `$feature-map-init`.
3. Match the requested feature by name and description.
4. Open only the first 2 to 3 files from `core_files`.
5. If `core_files` is missing or insufficient, read 1 to 2 files from `supporting_files` before expanding further.
6. If that is still insufficient, run the bundled `scripts/trace_flow.py --repo-root <target-repo> <file>` on one mapped file.
7. Read only 2 to 3 returned neighbors before expanding again.

## Rules

- Prefer the map over freeform repo exploration.
- Keep the first exploration pass intentionally narrow.
- Prefer `core_files` over `supporting_files` for the first pass.
- Use `supporting_files` to understand boundaries, orchestration, contracts, and adjacent context without crowding the initial read set.
- Use the tracer for deterministic expansion, not as a reason to read everything it returns.
- If the data you find is not enough, then and only then can you use the default explore agents, but let the user know you're about to do so.
