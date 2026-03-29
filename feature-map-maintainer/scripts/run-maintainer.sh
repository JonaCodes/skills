#!/bin/bash

set -euo pipefail

MODEL="gpt-5.4"
EFFORT="high"
RUN_LABEL="${MODEL/gpt-/codex-}-$EFFORT"

REPO_ROOT="${1:-$(pwd)}"
TMPFILE="$(mktemp)"
ERRFILE="$(mktemp)"
trap 'rm -f "$TMPFILE" "$ERRFILE"' EXIT

printf '\033[32mRunning maintainer with %s\033[0m\n' "$RUN_LABEL"

PROMPT=$(cat <<'PROMPT_EOF'
Task: In the target repository, maintain .ai/feature-map.yaml directly from staged git changes.

Requirements:
- Treat .ai/feature-map.yaml as the working source of truth.
- Read only staged changes using git diff --cached and git diff --cached --name-only.
- If there are no staged changes, say no map update is needed and stop without editing files.
- If .ai/feature-map.yaml is missing, explain that the map must exist before maintenance can run and exit non-zero.
- Maintain each feature entry using this shape when relevant:
  - name
  - description
  - core_files
  - supporting_files
- Use core_files for the files most directly responsible for the feature primary behavior.
- Use supporting_files for adjacent high-signal context such as app shells, bridge/protocol boundaries, shared contracts, config/state surfaces, service entrypoints, or one useful test.
- supporting_files is optional; omit it when there is no meaningful supporting context.
- Update only the affected map entries unless the staged diff clearly introduces a genuinely new feature area, in which case add a new top-level map entry.
- Keep both file lists lean and high-signal.
- If either list must exceed 5 files, keep the files and print a yellow warning line exactly as: Warning: feature list exceeds 5 files
- Write changes directly to .ai/feature-map.yaml when needed.
PROMPT_EOF
)

(
  cd "$REPO_ROOT"
  codex exec --skip-git-repo-check \
    -m "$MODEL" \
    -c "model_reasoning_effort=\"$EFFORT\"" \
    --output-last-message "$TMPFILE" \
    "$PROMPT" > /dev/null 2>"$ERRFILE" < /dev/null
)

EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  cat "$ERRFILE" >&2
  exit $EXIT_CODE
fi

if [[ -f "$REPO_ROOT/.ai/feature-map.yaml" ]]; then
  git -C "$REPO_ROOT" add .ai/feature-map.yaml
fi

while IFS= read -r line; do
  if [[ "$line" == Warning:* ]]; then
    printf '\033[33m%s\033[0m\n' "$line"
  else
    printf '%s\n' "$line"
  fi
done < "$TMPFILE"
