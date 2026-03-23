#!/bin/bash

# ask-codex skill - Run Codex with a prompt, letting it search the repo
# Usage: /ask-codex "your question" [--model MODEL] [--effort EFFORT]
# Defaults: model=gpt-5.3-codex, effort=medium
# Exit codes: 0=success, 1=codex error, 2=invalid model (cache cleared)

MODEL="gpt-5.3-codex"
EFFORT="medium"
PROMPT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --model)
      MODEL="$2"
      shift 2
      ;;
    --effort)
      EFFORT="$2"
      shift 2
      ;;
    *)
      # Everything else is the prompt
      PROMPT="$1"
      shift
      ;;
  esac
done

# Validate we have a prompt
if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided"
  echo "Usage: /ask-codex \"your question\" [--model MODEL] [--effort EFFORT]"
  exit 1
fi

# Run codex, capturing stderr to detect model errors
TMPFILE=$(mktemp)
ERRFILE=$(mktemp)
trap "rm -f $TMPFILE $ERRFILE" EXIT

FULL_PROMPT="Task: $PROMPT. Note that you should never nitpick or overengineer. Keep things simple."

codex exec --skip-git-repo-check \
  -m "$MODEL" \
  -c "model_reasoning_effort=\"$EFFORT\"" \
  --output-last-message "$TMPFILE" \
  "$FULL_PROMPT" > /dev/null 2>"$ERRFILE" < /dev/null

EXIT_CODE=$?

# Check stderr for model-rejection signals
STDERR_CONTENT=$(cat "$ERRFILE")
if echo "$STDERR_CONTENT" | grep -qiE "invalid model|model not found|unknown model|no such model"; then
  SKILL_CACHE="/Users/jona/.claude/skills/ask-codex/cached-codex-models.txt"
  rm -f "$SKILL_CACHE"
  exit 2
fi

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "$STDERR_CONTENT" >&2
  exit 1
fi

cat "$TMPFILE"
