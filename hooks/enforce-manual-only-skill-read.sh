#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/manual-only-skill-state.sh"

PAYLOAD="$(cat || true)"
SESSION_ID="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.session_id // empty' 2>/dev/null || true)"
TURN_ID="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.turn_id // empty' 2>/dev/null || true)"
CWD="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null || true)"

# Local tools have no universal read semantic, so inspect every string argument
# but return immediately for calls that do not mention a SKILL.md path.
TOOL_STRINGS="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.tool_input | ..? | strings' 2>/dev/null || true)"
if ! printf '%s\n' "$TOOL_STRINGS" | grep -q 'SKILL\.md'; then
  exit 0
fi

deny() {
  /usr/bin/jq -nc --arg reason 'This skill can only be read when the user explicitly asks for it.' \
    '{decision:"block",reason:$reason}'
  exit 0
}

STATE_FILE="$(manual_only_turn_file "$SESSION_ID" "$TURN_ID")"
STATE_SKILLS=""
if [ -n "$SESSION_ID" ] && [ -n "$TURN_ID" ] && [ -r "$STATE_FILE" ] &&
  /usr/bin/jq -e '(.skills | type == "array") and (.created_at | type == "string" and length > 0)' \
    "$STATE_FILE" >/dev/null 2>&1; then
  STATE_SKILLS="$(/usr/bin/jq -r '.skills[]? // empty' "$STATE_FILE" 2>/dev/null || true)"
fi

normalize_name() {
  local value="$1"
  value="$(manual_only_trim_scalar "$value")"
  printf '%s' "$value" | tr '[:upper:]' '[:lower:]'
}

is_authorized_name() {
  local requested="$1" skill
  requested="$(normalize_name "$requested")"
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    [ "$(normalize_name "$skill")" = "$requested" ] && return 0
  done <<< "$STATE_SKILLS"
  return 1
}

resolve_target() {
  local target="$1"
  case "$target" in
    /*) printf '%s' "$target" ;;
    ./*) printf '%s/%s' "${CWD:-.}" "$target" ;;
    *) printf '%s/%s' "${CWD:-.}" "$target" ;;
  esac
}

check_target() {
  local token="$1" target path body manual name
  # Remove shell punctuation and option prefixes while retaining a path.
  token="$(printf '%s' "$token" | sed -E 's/^[^A-Za-z0-9_./~:-]+//; s/[^A-Za-z0-9_.~\/:-]+$//')"
  case "$token" in
    *=*SKILL.md) token="${token##*=}" ;;
  esac
  [[ "$token" == SKILL.md || "$token" == */SKILL.md ]] || return 0
  target="$token"
  path="$(resolve_target "$target")"
  [ -f "$path" ] || return 0

  # Ordinary skills (including malformed/non-frontmatter files) remain allowed.
  body="$(manual_only_read_frontmatter "$path" 2>/dev/null || true)"
  [ -n "$body" ] || return 0
  manual="$(manual_only_frontmatter_value "$body" 'manual-only')"
  manual="$(normalize_name "$manual")"
  [ "$manual" = true ] || return 0

  name="$(manual_only_frontmatter_value "$body" name)"
  [ -n "$name" ] || deny
  is_authorized_name "$name" || deny
}

# Split each argument string into shell-ish tokens. Every token ending in
# SKILL.md is checked; all other tool arguments are ignored.
while IFS= read -r value; do
  [ -n "$value" ] || continue
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    case "$token" in *SKILL.md) check_target "$token" ;; esac
  done < <(printf '%s\n' "$value" | tr '\t\r\n' '   ' | tr ' ' '\n')
done <<< "$TOOL_STRINGS"
