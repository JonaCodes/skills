#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/manual-only-skill-state.sh"

PAYLOAD="$(cat || true)"
SESSION_ID="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.session_id // empty' 2>/dev/null || true)"
TURN_ID="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.turn_id // empty' 2>/dev/null || true)"

if [ -n "$SESSION_ID" ] && [ -n "$TURN_ID" ]; then
  manual_only_cleanup_turn "$SESSION_ID" "$TURN_ID"
else
  manual_only_maybe_cleanup_stale
fi

printf '{"continue":true}\n'
