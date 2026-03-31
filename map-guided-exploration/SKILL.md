---
name: map-guided-exploration
description: Use this to explore the codebase efficiently using the feature map in `.ai/feature-map.yaml`. This is useful when planning a new feature or investigating an existing one.
---

# Map Guided Exploration

Treat `.ai/feature-map.yaml` as the working source of truth for feature-oriented code navigation.

Each map entry separates `core_files` from `supporting_files`:

- `core_files` are the primary implementation files for the feature
- `supporting_files` are adjacent high-signal files that help explain or safely modify the feature

Use this skill to orchestrate cheap file triage before the main agent (you) reads code itself.

The `scripts/` paths in this skill are bundled with the skill itself, not with the target repository. Run them from the skill directory, or otherwise use the bundled script path with `--repo-root <target-repo>`.

## Workflow

1. Read `.ai/feature-map.yaml`.
2. If the map does not exist, tell the user to run `$feature-map-init`.
3. Match the requested feature by name and description.
4. Build a loose candidate set without reading candidate files yet:
   - include all `core_files` from the matched feature entry or entries
   - include any `supporting_files` whose names sound relevant to the request
   - when in doubt, include the file rather than excluding it
5. Before reading any candidate file yourself, send it to the custom `dora-explorer` subagent in small batches of 1 to 3 closely related files.
6. Give each `dora-explorer` invocation only:
   - the user request
   - the candidate file paths it should inspect
7. `dora-explorer` only decides whether the provided files are relevant or not relevant. It does not explore beyond the provided files.
8. Collect the files marked relevant across all batches.
9. Read only those relevant files yourself and continue planning or implementation from there.
10. If map-based triage is still insufficient after you read the shortlisted files, then and only then use the bundled `scripts/trace_flow.py --repo-root <target-repo> <file>` or broader exploration, using the same `dora-explorer` subagent for any additional file triage.
11. If getting trace files still doesn't help, then and only then can you ask the user to use broader exploration.

## Rules

- Keep candidate selection loose. False positives are cheaper than missing an important file.
- Select `core_files` and `supporting_files` by filename and feature description only. Do not pre-read them before triage.
- Use `dora-explorer` only for relevance triage, not for final reasoning or design decisions.
- Prefer `core_files` over `supporting_files` when batching candidates.
