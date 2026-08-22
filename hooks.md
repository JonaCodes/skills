# Hook bundles (written by Codex)

`hooks.json` connects the scripts in `hooks/` to Codex lifecycle events. Some scripts are standalone, while others depend on shared files and must be installed together.

## Manual-only skill bundle

These four files enforce skills that declare `manual-only: true`:

- `record-explicit-skill-invocations.sh` records skill names explicitly mentioned in the current user prompt.
- `enforce-manual-only-skill-read.sh` blocks access to a manual-only `SKILL.md` unless that skill was explicitly requested for the current turn.
- `manual-only-skill-state.sh` contains the shared state and frontmatter helpers used by the other scripts.
- `cleanup-manual-only-skill-state.sh` removes per-turn and stale state.

All four files are required. The recorder runs when a prompt is submitted, enforcement runs before tool use, and cleanup runs when the task stops.

## File-length bundle

These files work together:

- `check-file-length-stop.sh` checks changed and untracked text files before Codex stops.
- `file-length-policy.sh` defines the line limit, exclusions, path display, and optional project ignore-file behavior.

The checker sources the policy file at runtime, so keep both in the same directory. The policy can be customized without changing the hook logic.

## Standalone hooks

- `block-sensitive-file-access.sh` blocks tool access to common secret-bearing files such as `.env` and `.dev.vars`, while allowing example files.
- `format-after-apply-patch.sh` formats files changed through `apply_patch` when it can find Prettier.
- `check-tests.sh` runs a project-specific validation command before Codex stops.
- `check-time-handling-stop.sh` checks changed TypeScript files for project-specific time-handling rules.
- `play-jobs-done-if-codex-unfocused.sh` plays a completion sound when Codex is not the focused application.

The last three hooks contain project- or machine-specific assumptions and should be reviewed before reuse.

## Installation

Keep `hooks.json` and the entire `hooks/` directory together in the repository, then symlink both into the Codex configuration directory as described in the [README](README.md). Review `hooks.json` to enable, disable, or reorder hooks and update any machine-specific commands before use.
