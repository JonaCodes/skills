#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/manual-only-skill-state.sh"

PAYLOAD="$(cat || true)"
SESSION_ID="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.session_id // empty' 2>/dev/null || true)"
TURN_ID="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.turn_id // empty' 2>/dev/null || true)"
PROMPT="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.prompt // empty' 2>/dev/null || true)"

if [ -z "$SESSION_ID" ] || [ -z "$TURN_ID" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

manual_only_maybe_cleanup_stale
SESSION_DIR="$(manual_only_session_dir "$SESSION_ID")"
STATE_FILE="$(manual_only_turn_file "$SESSION_ID" "$TURN_ID")"
mkdir -p "$SESSION_DIR" 2>/dev/null || {
  printf '{"continue":true}\n'
  exit 0
}

# Match both $skill-name and /skill-name tokens. Names are normalized to
# lowercase and deduplicated while retaining their first occurrence.
SKILLS_JSON="$({
  printf '%s' "$PROMPT" |
    grep -oE '(^|[^[:alnum:]_])(\$|/)[[:alnum:]][[:alnum:]_.:-]*' 2>/dev/null |
    sed -E 's/^[^$\/]*//' |
    sed -E 's/^[$\/]//' |
    sed -E 's/[.,!?;)]*$//' |
    tr '[:upper:]' '[:lower:]' |
    awk 'NF && !seen[$0]++ { print }'
} | /usr/bin/jq -Rsc 'split("\n") | map(select(length > 0))')"

CREATED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
TEMP_FILE="$(mktemp "$SESSION_DIR/.turn.XXXXXX" 2>/dev/null || true)"
if [ -n "$TEMP_FILE" ]; then
  if /usr/bin/jq -nc --argjson skills "$SKILLS_JSON" --arg created_at "$CREATED_AT" \
    '{skills:$skills,created_at:$created_at}' >"$TEMP_FILE" 2>/dev/null; then
    mv -f -- "$TEMP_FILE" "$STATE_FILE" 2>/dev/null || rm -f -- "$TEMP_FILE" 2>/dev/null || true
  else
    rm -f -- "$TEMP_FILE" 2>/dev/null || true
  fi
fi

printf '{"continue":true}\n'
